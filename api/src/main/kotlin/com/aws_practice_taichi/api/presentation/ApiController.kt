package com.aws_practice_taichi.api.presentation

import org.springframework.boot.autoconfigure.EnableAutoConfiguration
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@EnableAutoConfiguration
class ApiController {
    @RequestMapping("/")
    fun home(): String {
        return "Hello World!!!"
    }
}