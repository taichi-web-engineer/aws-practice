package com.awsPracticeTaichi.api

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class ApiApplication

fun main(args: Array<String>) {
    // ossfテスト
    runApplication<ApiApplication>(*args)
}
