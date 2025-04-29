package com.awsPracticeTaichi.api.usecase

import com.awsPracticeTaichi.api.infra.repository.db.AwsTestRepository
import org.springframework.stereotype.Component

@Component
class ApiUsecase(private val awsTestRepo: AwsTestRepository) {
    fun getData(): List<String> {
        return awsTestRepo.findAll().map { it.testText   }
    }
}
