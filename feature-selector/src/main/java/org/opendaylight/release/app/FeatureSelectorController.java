/*
 * Copyright (c) 2014, 2015 Cisco Systems, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.release.app;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import javax.servlet.ServletContext;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Path;
import java.util.Properties;


@Controller
@RequestMapping("/")
public class FeatureSelectorController {

    @Autowired
    ServletContext context;
    private static Properties properties = readProperties();
    private static String[] featureList = getFeatureList(properties);


    /**
     * Method to list all the features on the UI
     *
     * @param model
     * @return
     */
    @RequestMapping(value="/features", method = RequestMethod.GET)
    public String viewFeatures(ModelMap model){
        model.addAttribute("features", featureList);
        return "index";
    }

    /**
     * This method receives a list of the features in a comma separated string.
     * It creates a new distribution zip that has those features as bootFeature in
     * karaf config file.
     * @param features
     * @return
     * @throws IOException
     */
    @RequestMapping(value="/selectFeatures", method = RequestMethod.POST)
    @ResponseBody
    public String selectFeatures(@RequestParam(value="selectedFeatures", required=false) String features) throws IOException {
        FileUtil fileUtil = FileUtil.getInstance(properties, context);

        // Copy original distribution to unique location
        Path destFile = fileUtil.copyOriginalDistro(context);

        // Update the config file at destination file
        fileUtil.updateConfigFileWithFeatures(features, destFile);

        // Return path to download new distribution
        StringBuilder builder = new StringBuilder();
        builder.append(context.getContextPath()).append(FileUtil.DEST_DISTRO_PATH).append(destFile.getParent().getFileName())
            .append("/").append(destFile.getFileName());

        return builder.toString();
    }

    private static Properties readProperties() {
        Properties prop = new Properties();
        String filename = "config.properties";

        try(InputStream input = FeatureSelectorController.class.getClassLoader().getResourceAsStream(filename)) {
            //load a properties file from class path, inside static method
            prop.load(input);

        } catch (IOException ex) {
            ex.printStackTrace();
        }
        return prop;
    }

    private static String[] getFeatureList(Properties prop) {
        String[] features = null;
        String feature = prop.getProperty("features");
        if(feature != null) {
            features = feature.split(",");
        }
        return features;
    }



}
