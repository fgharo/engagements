package com.example.vaultdemo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@SpringBootApplication
@Configuration
public class VaultDemoApplication implements CommandLineRunner {
    @Autowired
    Environment env;
    
    @Value("${vault-demo.made.up.property:Default made up property!!!}")
    String madeUpValue;
    
	public static void main(String[] args) {
		SpringApplication.run(VaultDemoApplication.class, args);
	}

    @Override
    public void run(String... args) throws Exception {
        log.info("Vault value injected via Environment class vault-demo.made.up.property: {}", env.getProperty("vault-demo.made.up.property"));
        log.info("Vault value injected via Value annotation vault-demo.made.up.property: {}", madeUpValue);
    }

}
