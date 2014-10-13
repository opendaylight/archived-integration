
/*
 * Copyright (c) 2014 Cisco Systems, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.release.app;

import javax.servlet.ServletContext;
import java.io.BufferedReader;
import java.io.IOException;
import java.net.URI;
import java.nio.charset.Charset;
import java.nio.file.FileSystem;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

public class FileUtil {
    private volatile static FileUtil instance;

    // Path of the source distribution file
    private Path sourcePath = null;

    // content of karaf config file
    private String featureConfigContent = null;

    // config file location inside the zip file
    private String configFileLocation = null;

    public static String FEATURE_SELECTION_REPLACEMENT = "{CHANGE_ME}";

    // location of all generated distributions inside tomcat
    public static String DEST_DISTRO_PATH = "/download/generated/";

    public static FileUtil getInstance(Properties properties, ServletContext context) throws IOException {
        if (instance == null) {
            synchronized (FileUtil.class) {
                if (instance == null) {
                    instance = new FileUtil(properties, context);
                }
            }
        }
        return instance;
    }

    private FileUtil(Properties properties, ServletContext context) throws IOException {
        initPath(properties, context);
        loadFeatureConfigFile();
    }


    /**
     * Based on config param, use provided source distribution or
     * get it from outside tomcat.
     *
     * @param context
     */
    private void initPath(Properties properties, ServletContext context) {
        // Check if external path of file is provided or not
        String externalFilePath = properties.getProperty("distribution-file-path");
        String distFileName = properties.getProperty("distribution-filename");
        if(distFileName == null || distFileName.isEmpty()) {
            throw new IllegalStateException("Distribution file name is missing in config file.");
        }
        if(externalFilePath != null && !externalFilePath.isEmpty()) {
            sourcePath = Paths.get(externalFilePath + "/" + distFileName);
            System.out.println("picking external file");
        } else {
            sourcePath = Paths.get(context.getRealPath("/download/original/" + distFileName));
        }

        configFileLocation = "/" + distFileName.substring(0, distFileName.lastIndexOf("."))
            + "/etc/org.apache.karaf.features.cfg";

    }

    /**
     *
     * Load the feature config files's content in String and keep it in memory. Add a CHANGE_ME keyword,
     * that will be used during each new distribution creation
     *
     */

    private void loadFeatureConfigFile() throws IOException {
        try (FileSystem sourceFileSystem = createZipFileSystem(sourcePath)) {
            final Path featureConfig = sourceFileSystem.getPath(configFileLocation);
            try (BufferedReader reader = Files.newBufferedReader(featureConfig, Charset.forName("UTF-8"))) {
                StringBuilder fileContent = new StringBuilder();
                for (; ; ) {
                    String line = reader.readLine();
                    if (line == null)
                        break;
                    if (line.contains("featuresBoot=")) {
                        line = line.concat(FEATURE_SELECTION_REPLACEMENT);
                    }
                    fileContent.append(line).append("\n");
                }
                featureConfigContent = fileContent.toString();
            }

        }
    }

    /**
     * Creates a zipFile system based on the path of the zip file.
     * It does not create a zip file, if it does not exists.
     * @param path
     * @return
     * @throws IOException
     */
    public FileSystem createZipFileSystem(Path path) throws IOException {
        final URI uri = URI.create("jar:file:" + path.toUri().getPath());

        final Map<String, String> env = new HashMap<>();
        env.put("create", "false");
        return FileSystems.newFileSystem(uri, env);
    }


    /**
     * Copy the Source distribution to a new location directory created
     * based on the time stamp on every request
     * @param context
     * @return
     * @throws IOException
     */
    public Path copyOriginalDistro(ServletContext context) throws IOException {
        Date now = new Date();
        String directoryName = String.valueOf(now.getTime());
        Path destDir =  Paths.get(context.getRealPath(DEST_DISTRO_PATH + directoryName ));
        Files.createDirectories(destDir);
        Path destFile = destDir.resolve(sourcePath.getFileName());
        Files.copy(sourcePath, destFile);
        return destFile;
    }

    /**
     * Creates a new config file with user selected features
     * and move it inside the new destination zip file
     */
    public void updateConfigFileWithFeatures(String features, Path destFile) throws IOException {
        // Create new config file
        String fileContent = featureConfigContent.replace(FEATURE_SELECTION_REPLACEMENT, features);
        Path newConfFile = destFile.getParent().resolve("org.apache.karaf.features.cfg");
        Files.write(newConfFile, fileContent.getBytes());

        // replace older config file with new one
        try(FileSystem destFileSystem = createZipFileSystem(destFile)){
            final Path oldConfFile = destFileSystem.getPath(configFileLocation);
            Files.move(newConfFile, oldConfFile, StandardCopyOption.REPLACE_EXISTING);
        }
    }
}
