package com.wlanboy.cloudconfigpropertygenerator;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = "CONFIGMAP_FILE_TO_WRITE=./output/configmap.yaml")
public class CloudconfigpropertygeneratorApplicationTests {

	@Test
	public void contextLoads() {
	}

}
