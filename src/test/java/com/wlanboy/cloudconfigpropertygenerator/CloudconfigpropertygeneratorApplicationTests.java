package com.wlanboy.cloudconfigpropertygenerator;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
		"CONFIGMAP_FILE_TO_WRITE=./output/configmap.yaml",
		"SPRING_CLOUD_CONFIG_URI=http://localhost:8888",
		"SPRING_PROFILES_ACTIVE=default",
		"SPRING_APPLICATION_NAME=cloudconfigpropertygenerator"
})
public class CloudconfigpropertygeneratorApplicationTests {

	@Test
	public void contextLoads() {
	}

}
