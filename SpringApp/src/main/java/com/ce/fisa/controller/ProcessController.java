package com.ce.fisa.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestController
public class ProcessController {
	
	@GetMapping("/test")
	public String reqRes() {
		log.info("요청 수락 ~~~");
		return "linux 서버에서 실행되는 app";
	}
}
