package com.wlanboy.cloudconfigpropertygenerator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.EnumerablePropertySource;
import org.springframework.core.env.PropertySource;
import org.springframework.stereotype.Component;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;

@Component
public class PropertyGenerator implements CommandLineRunner {

	private static final Logger log = LoggerFactory.getLogger(PropertyGenerator.class);

	private final ConfigurableEnvironment env;

	@Value("${CONFIGMAP_FILE_TO_WRITE:configmap.yaml}")
	private String configmapFileToWrite;

	@Value("${spring.application.name}")
	private String applicationName;

	public PropertyGenerator(ConfigurableEnvironment env) {
		this.env = env;
	}

	@Override
	public void run(String... args) throws Exception {
		log.info("Merging all properties from Spring Environment");

		Properties merged = new Properties();

		for (PropertySource<?> ps : env.getPropertySources()) {

			// ❌ System Environment komplett ignorieren
			if (ps.getName().contains("systemEnvironment")) {
				continue;
			}

			// ❌ System Properties komplett ignorieren
			if (ps.getName().contains("systemProperties")) {
				continue;
			}

			if (ps instanceof EnumerablePropertySource<?> enumerable) {

				log.info("Reading PropertySource: {}", ps.getName());

				for (String key : enumerable.getPropertyNames()) {

					if (isIgnoredKey(key))
						continue;

					Object value = ps.getProperty(key);
					if (value == null)
						continue;

					String cleaned = sanitizeValue(String.valueOf(value));
					merged.put(key, cleaned);
				}
			}
		}

		Properties sorted = sortProperties(merged);

		writeConfigMap(sorted);

		log.info("Finished generating Kubernetes ConfigMap");
	}

	private boolean isIgnoredKey(String key) {
		return key.startsWith("management.endpoint.") ||
				key.startsWith("logging.") ||
				key.startsWith("spring.liveBeansView") ||
				key.contains("password") ||
				key.contains("secret");
	}

	private String sanitizeValue(String value) {
		return value.replace("\n", "")
				.replace("\r", "")
				.replace("\t", "")
				.trim()
				.replace("\"", "\\\"");
	}

	private Properties sortProperties(Properties props) {
		Properties sorted = new Properties();
		props.keySet().stream()
				.map(String.class::cast)
				.sorted()
				.forEach(k -> sorted.put(k, props.getProperty(k)));
		return sorted;
	}

	private void writeConfigMap(Properties props) {
		try {
			Path path = Path.of(configmapFileToWrite);
			log.info("Writing ConfigMap to {}", path.toAbsolutePath());

			StringBuilder yaml = new StringBuilder();
			yaml.append("apiVersion: v1\n");
			yaml.append("kind: ConfigMap\n");
			yaml.append("metadata:\n");
			yaml.append("  name: ").append(applicationName).append("-config\n");
			yaml.append("data:\n");
			yaml.append("  application.properties: |\n");

			for (String key : props.stringPropertyNames()) {
				yaml.append("    ").append(key).append("=")
						.append(props.getProperty(key))
						.append("\n");
			}

			Files.writeString(path, yaml.toString());

		} catch (Exception e) {
			log.error("Error writing ConfigMap", e);
		}
	}
}
