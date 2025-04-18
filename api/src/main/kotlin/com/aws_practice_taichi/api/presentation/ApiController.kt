package com.aws_practice_taichi.api.presentation

import com.aws_practice_taichi.api.usecase.ApiUsecase
import org.springframework.boot.autoconfigure.EnableAutoConfiguration
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@EnableAutoConfiguration
class ApiController(private val apiUsecase: ApiUsecase) {
    @RequestMapping("/")
    fun home(): List<String> {
        return apiUsecase.getData()
    }
}