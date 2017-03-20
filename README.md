# drupal-security-audit

Drupal site security audit instruction from https://drupal-admin.com

# Drupal site security audit step-by-step

There are 10 steps to Drupal site security audit as performed by our team https://drupal-admin.com :

1. Website isolation.
1. Search for malicious code.
1. Search for changes in Drupal core and modules.
1. Search for new files in Drupal core and modules directories.
1. Search for code needing security check.
1. Search for PHP and JS in DB.
1. Search for queries uncharacteristic for Drupal.
1. Checking installation with security_review.
1. Checking for susceptibility to Drupalgeddon.
1. Checking web server settings.

# 1. Website isolation

We need to isolate the website to avoid changing files and database while performing the audit. Skip this step and you may end up with more files containing malicious code than there were at the outset.

There are two typical isolation options:

* a docker container;
* a virtual server.

Pick any you like, they are much the same from the point of view of results achieved.

# 2. Search for malicious code

There are two products we use when searching for malicious code in Drupal website files:

* AI-Bolit, virus and malicious scripts scanner (server-side);
* Linux Malware Detect (LMD), a scanner for Linux that searches for web shells, spam bots, trojans etc.

My personal grand prix goes to AI-Bolit, since it does a better job finding malicious PHP and Perl code. But, again, your choice is your choice.

# 3. Search for changes in Drupal core and modules

To search for changes in Drupal core and modules, we install hacked + diff module (manually or via drush) and launch it to get a report.

Important: hacked module does not scan sites/all/libraries directory, so you should check it manually. Here is how you can do that:

1. download the library;
1. launch diff:
```
diff path_to_site/sites_default/libraries/name_library/ path_to_download_library/
```
1. analyze the changes found.

Nothing really complicated.

# 4. Search for new files in Drupal core and modules directories
At this step, we look for files that should not be part of the original core and modules downloaded from drupal.org.

To run the check, we use bash script drupal_find_new_files.sh. If there are no changes or some files differ, the script returns OK (with the exception of theme files). The script needs three arguments:

1. path to modules directory;
1. path to site’s root directory;
1. path to theme directory.

Launch the script in path_to_site/tmp/hacked_cache. This is where modules archives should be.

Once the script is through with the files, see report.log and check each file found with vi or less.

# 5. Search for code needing security check
We need to do this because hacked module report does not show all changes made to custom and dev modules. This is the step that results in a list of them.

# 6. Search for PHP and JS in DB
This is when we search for code injections into the DB. First off, you need a DB dump:
```
mysqldump -uuser -ppassword db > db.sql
```
Then you can generate a number of reports:
```
cat db.sql | grep '<?php[^<]*>' > report_php.log
cat db.sql | grep '<script[^<]*>' > report_script.log
cat db.sql | grep '<object[^<]*>' > report_object.log
cat db.sql | grep '<iframe[^<]*>' > report_iframe.log
cat db.sql | grep '<embed[^<]*>' > report_embed.log
```
You can use any editor to analyze the reports. We prefer vi, since the search function is faster in this editor. In each report, we search for keywords from commands mentioned above, e.g. in report_embed.log we search for “embed” and look at the surroundings of each entry found. Sticking to the example, it can be some object between <embed></embed> tags.

# 7. Search for queries uncharacteristic for Drupal

At this stage, we analyze web server logs and look for queries you do not associate with a Drupal-powered website.

This is a 3-step procedure: CD to logs directory, run commands, get your results and analyze them.

Scooping queries to PHP files:
```
cat log_access.log | awk ' { if($9==200)  print $7 } ' |  grep \.php | grep -v "index\.php" > php.log
```
Check what PHP files were executed successfully, see if any of them are on the list compiled at step 1 (antivirus check), open each file and analyze its contents.

Scooping CGI quesries:
```
cat log_access.log | awk ' { print $7 } ' | grep "\.cgi" > cgi.log
```
Scooping POST-queries:
```
cat log_access.log | grep POST | awk ' { print $6 $7 } ' | sort | uniq -c | sort -rn > post.log
```
Here, we check successful POST-queries to the website, although the queries can be to PHP files as well. The routine applied is described above: see if any of them are on the list compiled at step 1 (antivirus check), open each file and analyze its contents.

# 8. Checking installation with security_review
As the name of the step implies, this is when we check the installation with the security_review module and get rid of all annoying nuances following recommendations.

Install security_review manually or via drush, launch it, get the report, check it and fix everything step-by-step.

# 9. Checking for susceptibility to Drupalgeddon
If the website’s core was not updated for a long time, it makes sense to check if it is susceptible to Drupalgeddon. This vulnerability enjoys some outstanding coverage online. We follow the routine described below:

Checking with https://www.drupal.org/project/drupalgeddon

Search for files:
```
find ./ -type f -name "*.php" -exec grep -l '$form1=@$_COOKIE' {} \; >> report.log
```
Search through the DB:
```
SELECT * FROM menu_router WHERE access_arguments LIKE '%form1(@$_COOKIE%';
SELECT * FROM role WHERE name='megauser';
SELECT * FROM users WHERE name='drupadev';
SELECT * FROM users WHERE name='drupaldev';
SELECT * FROM users WHERE name='drupdev';
```
# 10. Checking web server settings
Web server environment for a Drupal website is a yet another topic covered excessively online. At drupal.org, there are many articles dealing with Drupal security: https://www.drupal.org/security/secure-configuration

We check the following:
1. owner and permissions (find recommendations here: https://www.drupal.org/node/244924)
1. Possibility of PHP files execution from /sites/default/files (find recommendations here: https://www.drupal.org/node/615888)
