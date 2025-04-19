package com.awsPracticeTaichi.api.infra.entity.db

import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table

@Entity
@Table(name = "aws_test")
data class AwsTest(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Int,
    var testText: String
)
