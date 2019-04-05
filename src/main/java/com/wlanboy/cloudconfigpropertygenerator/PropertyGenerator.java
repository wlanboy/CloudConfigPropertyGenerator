package com.wlanboy.cloudconfigpropertygenerator;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.util.Properties;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.EnumerablePropertySource;
import org.springframework.core.env.PropertySource;
import org.springframework.stereotype.Component;
import org.springframework.util.DefaultPropertiesPersister;

@Component
public class PropertyGenerator implements CommandLineRunner {

	private final Logger logger = LoggerFactory.getLogger(PropertyGenerator.class);

	@Autowired
	ConfigurableEnvironment env;
	
	@Value("${PROPERTY_FILE_TO_WRITE}")
	String PROPERTY_FILE_TO_WRITE;
	
	@Value("${spring.application.name}")
	String APPLICATION_NAME;

	@Override
	public void run(String... args) throws Exception {
		logger.info("Generating properties");
		String key = null;
		String value = null;

		Properties propertyFile = new Properties();
		
		for (PropertySource<?> propertySource : env.getPropertySources()) {
			if (propertySource instanceof EnumerablePropertySource) {
				logger.info("=====================================================================");
				logger.info("propertySource: " + propertySource.getName());

				if ("bootstrapProperties".equals(propertySource.getName())) {
					String[] propertyNames = ((EnumerablePropertySource<?>) propertySource).getPropertyNames();
					for (int i = 0; i < propertyNames.length; i++) {
						key = propertyNames[i];
						value = String.valueOf(propertySource.getProperty(key));
						logger.info(key + " -- " + value);
						propertyFile.setProperty(key, value);
					}
				}
				logger.info("=====================================================================");
			}
		}

		try {
			File f = new File(PROPERTY_FILE_TO_WRITE);
			OutputStream out = new FileOutputStream(f);
			DefaultPropertiesPersister p = new DefaultPropertiesPersister();
			p.store(propertyFile, out, "Header: "+APPLICATION_NAME);
			out.close();
		} catch (Exception e) {
			logger.error("DefaultPropertiesPersister",e);
		}

	}

}
