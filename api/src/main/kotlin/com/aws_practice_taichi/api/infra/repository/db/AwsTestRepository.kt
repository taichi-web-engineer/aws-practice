package com.aws_practice_taichi.api.infra.repository.db

import com.aws_practice_taichi.api.infra.entity.db.AwsTest
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface AwsTestRepository : JpaRepository<AwsTest, Long>