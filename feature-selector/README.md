Feature Selector is a simple web application, that allows user to pick features from a list of available features.
Then, add those selected features to the karaf feature config file "org.apache.karaf.features.cfg" as bootFeatures
and return a link to download distribution that has new feature config file.

config.properties file present under resources. Here are the details of config.properties -

features=odl-restconf,odl-dlux-core,odl-mdsal-clustering : (Required) Comma separated list of features that you want user to select from.

distribution-filename=distribution-dlux-0.1.0-SNAPSHOT.zip : (Required) File name of the distribution zip

distribution-file-path=/opt/dist : (Optional) Location of the zip file, if you are not providing it within war file

Release distribution zip file can be placed inside the war at location /webapp/download/original, Or
it could be picked up from the file system path, specified by configuration property distribution-file-path.

Note: Just make sure to provide either external location of distribution directory using property "distribution-file-path" or
place zip file inside war at /webapp/download/original. One of these is required.



