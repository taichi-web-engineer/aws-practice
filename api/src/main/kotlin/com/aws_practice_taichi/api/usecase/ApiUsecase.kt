package com.aws_practice_taichi.api.usecase

import com.aws_practice_taichi.api.infra.repository.db.AwsTestRepository
import org.springframework.stereotype.Component

@Component
class ApiUsecase(private val awsTestRepo: AwsTestRepository) {
    fun getData(): List<String> {
        return awsTestRepo.findAll().map { it.testText }
    }
}