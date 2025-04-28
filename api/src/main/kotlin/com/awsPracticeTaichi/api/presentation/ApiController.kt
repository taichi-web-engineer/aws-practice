package com.awsPracticeTaichi.api.presentation

import com.awsPracticeTaichi.api.usecase.ApiUsecase
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController

@RestController
class ApiController(private val apiUsecase: ApiUsecase) {
    @GetMapping("/")
    fun home(): List<String> {
        return apiUsecase.getData()
    }
}
