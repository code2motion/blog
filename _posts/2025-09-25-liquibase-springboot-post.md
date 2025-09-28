---
layout: single
title: "Liquibase Implementation With Springboot Hibernate"
date: 2025-09-25
categories: [blog]
tags: [springboot, hibernate, liquibase, database]
header:
  overlay_image: assets/images/blog/2025-09-25/liquibase2.png
  teaser: assets/images/blog/2025-09-25/liquibase.png
excerpt: |
  In this post, we’ll explore a high-level implementation of Liquibase with Spring Boot and Jpa, using Hibernate for database interactions.
comments: true
---

# Liquibase Implementation With Springboot Hibernate

> In this post, we’ll explore a high-level implementation of Liquibase with Spring Boot and Jpa, using Hibernate for database interactions.

---

## Table of Contents

- [What is liquibase ?](#what-is-liquibase-?)
- [Liquibase with gradle](#liquibase-with-gradle)
- [Autogenerate diff and how to metion it in the springboot to auto upgrade db ?](#autogenerate-diff-and-how-to-metion-it-in-the-springboot-to-auto-upgrade-db-?s)
- [How to upgrade or downgrade with liquibase](#how-to-upgrade-or-downgrade-with-liquibase)
- [Liquibase limitations compared to other language migrations](#liquibase-limitations-compared-to-other-language-migrations)
- [Final thoughts](#final-thoughts)

---

## What is liquibase ?

Liquibase is a database migration management tool that helps you manage and track changes to your database in a safe and controlled way. It integrates well with Spring Boot and other frameworks, ensuring that schema updates are consistent across environments. Every change you make whether it’s adding a column, creating a table, or modifying data is stored in change scripts, which also serve as a historical record of what was changed and when.

Liquibase supports multiple formats for writing these change scripts, including YAML, SQL, XML, and JSON. This flexibility allows teams to choose whichever format they’re most comfortable with. Once defined, these scripts can be version controlled along with your application code, ensuring database and application changes are deployed together.

Another key benefit is its ability to both apply (upgrade) and roll back (downgrade) changes. If a deployment introduces issues, you can revert to a previous state, as long as rollback scripts are provided. This makes Liquibase especially valuable in CI/CD pipelines, where reliable and reversible database migrations are critical for smooth delivery.


## Liquibase with gradle

In this series of blog posts, I’m exploring how to use Liquibase with Spring Boot, leveraging the Gradle Liquibase plugin and the necessary dependencies. During discussions with other developers, I realized that Liquibase comes with a few technical challenges compared to database management tools in other languages. For example, Python’s Flask with SQLAlchemy feels more developer-friendly in some ways, because it can automatically detect ORM model changes and generate both upgrade and downgrade SQL scripts based on previous migrations. With Liquibase, this process isn’t always as straightforward, and when I tried implementing it, a few things were unclear.

In this article, I plan to shed light on some of those hidden details and share the issues I faced while working with Liquibase. I’ll also welcome feedback—if I’ve misunderstood or done something incorrectly, please feel free to point it out in the discussion section. I intend to update this blog based on your comments so that others can benefit from a more accurate picture.

One of the first hurdles I encountered was figuring out the right dependencies when using the Gradle Liquibase plugin. It took quite a bit of trial and error to land on a working combination, as certain versions produced strange or inconsistent errors. Eventually, I managed to identify a set of compatible versions and got a working example up and running, which I’ll also share here.

#### What does Liquibase gradle plugin do ?

The Gradle Liquibase Plugin integrates Liquibase directly into the Gradle build lifecycle, allowing database change management tasks to be executed within the Gradle environment. With this plugin, developers can generate, apply, and roll back database schema changes using simple Gradle commands—removing the need to run Liquibase separately.

Key capabilities include:

1. Running Liquibase commands (update, rollback, status, validate, diff, etc.) through Gradle tasks.
2. Generating and executing database upgrade and downgrade scripts.
3. Managing changelogs and ensuring consistent schema versioning across environments.
4. Seamlessly integrating database migrations into CI/CD pipelines via Gradle tasks.
5. Supporting multiple database environments (e.g., dev, test, prod) with configurable properties.
6. Ensuring database state remains in sync with application releases.

In short, the plugin brings Liquibase into the Gradle workflow, enabling unified build and database version control from a single environment.

While using this plugin, I faced a few drawbacks. One challenge was finding the exact matching Liquibase dependencies required to enable the Gradle plugin. There isn’t much documentation about which dependencies to use with the latest versions, so I had to figure it out through trial and error. Eventually, I found a combination that worked for me, but there may be other reliable sources where we can find the right dependencies.

Gradle plugin gradle version I have used 

```gradle
id 'org.liquibase.gradle' version "3.0.2"
```

Other dependencies that required 

```gradle
liquibaseRuntime 'org.liquibase:liquibase-core:4.26.0'
liquibaseRuntime 'org.liquibase:liquibase-groovy-dsl:3.0.2'
liquibaseRuntime 'info.picocli:picocli:4.6.1'
liquibaseRuntime 'org.liquibase.ext:liquibase-hibernate6:4.26.0'
liquibaseRuntime 'org.postgresql:postgresql:42.7.4'
liquibaseRuntime files(sourceSets.main.output)

implementation 'org.liquibase:liquibase-core:4.26.0'
```

In my setup, I added the Spring Boot Liquibase dependency so that any changes added to the changelog are automatically detected and applied to the database when the application starts. This is convenient for local development, but in production you should disable automatic updates to avoid unintended schema changes. Here we use two dependency configurations: `liquibaseRuntime` for the Gradle Liquibase plugin, and `implementation` for Spring Boot. The first is required for running Liquibase commands through Gradle, while the second ensures Spring Boot can pick up Liquibase at runtime.

I also added liquibaseRuntime files(sourceSets.main.output) as a dependency. This tells the Liquibase Gradle plugin to include the compiled output of the main source set (for example, `build/classes/java/main` and resources like `src/main/resources`) on the Liquibase runtime classpath. By doing this, Liquibase can detect changes in the database models and generate an update changelog (diff) with the latest schema modifications. However, it does not generate downgrade scripts automatically. According to the documentation, this is by design Liquibase avoids auto-generating rollbacks to reduce the risk of accidental data loss. Instead, developers are expected to write rollback scripts manually when needed.

```gradle
configurations {
  liquibaseRuntime.extendsFrom runtimeClasspath
}
```

This is needed because the Liquibase Gradle plugin runs in its own configuration (liquibaseRuntime), separate from the application’s runtimeClasspath. By default, Liquibase tasks won’t know about the dependencies we have already declared for the app (like JDBC drivers, Hibernate, or Spring Data). Extending liquibaseRuntime from runtimeClasspath makes sure all the libraries available at runtime for the application are also available to Liquibase when it executes. Without this, Liquibase might fail to connect to the database or to detect changes in entities, since it wouldn’t have the necessary classes and drivers on its classpath.

```gradle
liquibase {
  runList = 'main'
  activities {
    main {
      changelogFile "db/changelog/db.changelog-master.yml"
      url "jdbc:postgresql://localhost:5432/budget_wise"
      username "budget_wise"
      password "budget_wise"
      outputSchemas "public"
      includeSchema false
      referenceUrl """hibernate:spring:com.budgetwise,com.budgetwise.backend.models
        ?dialect=org.hibernate.dialect.PostgreSQLDialect
        &hibernate.default_schema=public
        &hibernate.physical_naming_strategy=org.hibernate.boot.model.naming.CamelCaseToUnderscoresNamingStrategy
        &hibernate.implicit_naming_strategy=org.springframework.boot.orm.jpa.hibernate.SpringImplicitNamingStrategy"""
    }
  }
}
```

This Gradle configuration defines a main Liquibase activity and tells the plugin how to connect to the database and where to find the changelog (db/changelog/db.changelog-master.yml). The JDBC URL, username, and password let Liquibase log in and apply changes when you run update. The referenceUrl uses the Liquibase Hibernate integration to point at your Java packages; it’s used for diff/generateChangeLog so Liquibase can compare your Hibernate entities to the database and produce a changeset. The query parameters set the PostgreSQL dialect, default schema, and naming strategies so Hibernate maps names the same way your app does, which yields accurate diffs. Options like outputSchemas and includeSchema scope and format the generated output. Since this example targets PostgreSQL, the config specifies the Postgres dialect. For security and portability, avoid hardcoding credentials use Gradle properties or environment variables instead.

Following is the Example spring boot configuration that can be used [Example Project](https://github.com/nuwan-samarasinghe/budget-wise/blob/main/backend/build.gradle)

```gradle
buildscript {
  repositories {
    mavenCentral()
  }
  dependencies {
    classpath 'org.liquibase:liquibase-core:4.26.0'
  }
}

plugins {
	id 'java'
	id 'org.springframework.boot' version '3.5.3'
	id 'io.spring.dependency-management' version '1.1.7'
	id 'com.diffplug.spotless' version '6.25.0'
	id "org.sonarqube" version "6.2.0.5505"
	id 'jacoco'
  id 'org.liquibase.gradle' version "3.0.2"
}

group = 'com.budgetwise'
version = '0.0.1-SNAPSHOT'

java {
	toolchain {
		languageVersion = JavaLanguageVersion.of(21)
	}
	sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}

spotless {
    java {
        googleJavaFormat()
        eclipse()
        removeUnusedImports()
        trimTrailingWhitespace()
        endWithNewline()
    }
}

jacoco {
    toolVersion = "0.8.11"
}

jacocoTestReport {
    dependsOn test

    reports {
        xml.required = true
        csv.required = false
        html.outputLocation = layout.buildDirectory.dir('jacocoHtml')
    }
}

jacocoTestCoverageVerification {
    dependsOn jacocoTestReport
    violationRules {
        rule {
            limit {
                minimum = 0.80
            }
        }
    }
}

configurations {
    developmentOnly
    runtimeClasspath {
        extendsFrom developmentOnly
    }
}

bootRun {
    jvmArgs = [
        "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
    ]
	sourceResources sourceSets.main
}

sonar {
  properties {
    property "sonar.projectKey", "budget-wise-backend"
    property "sonar.organization", "nuwan-samarasinghe"
    property "sonar.host.url", "https://sonarcloud.io"
	property "sonar.java.binaries", "build/classes/java/main"
	property "sonar.coverage.jacoco.xmlReportPaths", "${buildDir}/reports/jacoco/test/jacocoTestReport.xml"
  }
}

repositories {
	mavenCentral()
	maven { url = 'https://repo.spring.io/milestone' }
	maven { url = 'https://repo.spring.io/snapshot' }
}

configurations {
  liquibaseRuntime.extendsFrom runtimeClasspath
}

dependencies {
	implementation 'org.springframework.boot:spring-boot-starter-actuator'
	implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
	implementation 'org.springframework.boot:spring-boot-starter-security'
	implementation 'org.springframework.boot:spring-boot-starter-validation'
	implementation 'org.springframework.boot:spring-boot-starter-web'
  implementation 'org.liquibase:liquibase-core:4.26.0'
  implementation 'org.springframework.boot:spring-boot-starter-aop'
  implementation 'org.modelmapper:modelmapper:3.2.4'
  implementation 'org.springdoc:springdoc-openapi-starter-webmvc-ui:2.8.9'
  liquibaseRuntime 'org.liquibase:liquibase-core:4.26.0'
  liquibaseRuntime 'org.liquibase:liquibase-groovy-dsl:3.0.2'
  liquibaseRuntime 'info.picocli:picocli:4.6.1'
  liquibaseRuntime 'org.liquibase.ext:liquibase-hibernate6:4.26.0'
  liquibaseRuntime 'org.postgresql:postgresql:42.7.4'
  liquibaseRuntime files(sourceSets.main.output)
	runtimeOnly 'org.postgresql:postgresql'
	compileOnly 'org.projectlombok:lombok'
  implementation 'io.jsonwebtoken:jjwt-api:0.12.6'
  runtimeOnly 'io.jsonwebtoken:jjwt-impl:0.12.6'
  runtimeOnly 'io.jsonwebtoken:jjwt-jackson:0.12.6'
	annotationProcessor 'org.projectlombok:lombok'
	testImplementation 'org.springframework.boot:spring-boot-starter-test'
	testImplementation 'org.springframework.boot:spring-boot-testcontainers'
	testImplementation 'org.springframework.security:spring-security-test'
	testImplementation 'org.testcontainers:junit-jupiter'
	testImplementation 'org.testcontainers:postgresql'
	testImplementation 'net.datafaker:datafaker:2.4.3'
	testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
	developmentOnly 'org.springframework.boot:spring-boot-devtools'
}

tasks.withType(org.liquibase.gradle.LiquibaseTask).configureEach {
  dependsOn("classes")
}

tasks.register("printLiquibaseRuntime") {
  doLast {
    configurations.liquibaseRuntime.resolve().each { println it }
  }
}

liquibase {
  runList = 'main'
  activities {
    main {
      changelogFile "db/changelog/db.changelog-master.yml"
      url "jdbc:postgresql://localhost:5432/budget_wise"
      username "budget_wise"
      password "budget_wise"
      outputSchemas "public"
      includeSchema false
      referenceUrl """hibernate:spring:com.budgetwise,com.budgetwise.backend.models
        ?dialect=org.hibernate.dialect.PostgreSQLDialect
        &hibernate.default_schema=public
        &hibernate.physical_naming_strategy=org.hibernate.boot.model.naming.CamelCaseToUnderscoresNamingStrategy
        &hibernate.implicit_naming_strategy=org.springframework.boot.orm.jpa.hibernate.SpringImplicitNamingStrategy"""
    }
  }
}

tasks.named('test') {
	useJUnitPlatform()
	testLogging {
        events "passed", "skipped", "failed"
    }
}

check.dependsOn jacocoTestCoverageVerification

```

## Autogenerate diff and how to metion it in the springboot to auto upgrade db ?

To auto-generate the initial changelog, I run:

```sh
./gradlew generateChangelog -PliquibaseChangelogFile=src/main/resources/db/changelog/db.changelog-master.yml
```
This tells Liquibase (via the Gradle plugin) to scan my reference model (Hibernate, per my referenceUrl) and the target database, then write the “main” changelog to db.changelog-master.yml. I treat this as the baseline of my schema.

After that baseline exists, anytime I change my entities, I generate a new, timestamped changeset with:
```sh
./gradlew clean classes && ./gradlew diffChangelog -PliquibaseChangelogFile=src/main/resources/db/changelog/changesets/$(date +%Y-%m-%d-%H%M).yml
```
I run clean classes first so the compiled classes match my latest code; otherwise the diff might be stale. diffChangelog compares the updated model to the current database and outputs only the differences into a new changeset file named with the current date/time. I then review and, if needed, add explicit rollback blocks before committing.

In Spring Boot, I use these properties:
```
spring.jpa.hibernate.ddl-auto=validate
spring.liquibase.enabled=true
spring.liquibase.change-log=classpath:db/changelog/db.changelog-master.yml
```
* `ddl-auto=validate` makes Hibernate check the schema rather than auto-create/update it, so Liquibase remains the single source of truth.
* `spring.liquibase.enabled=true` lets Spring Boot run Liquibase on startup (great for local/dev).
* `change-log` points Boot to my master changelog, which can include the generated changesets.

A few tips:

* Keep credentials and JDBC URLs out of build files; use Gradle properties or environment variables.
* Don’t rely on Boot auto-updates in production—run Liquibase via Gradle/CI instead.
* Always review generated diffs and write rollbacks manually where appropriate.

## How to upgrade or downgrade with liquibase

To apply (upgrade) the database to the latest version defined in your changelogs, I simply run: 

```sh
./gradlew update
```
This tells Liquibase to look at the current state of the database, compare it with the changelogs, and then apply any new changesets that haven’t been executed yet. It’s the most common command and is what keeps the database schema in sync with my code.

Downgrading (rolling back) works a little differently. Liquibase doesn’t auto-generate downgrade scripts for safety reasons—you need to define explicit rollback instructions inside your changesets. For example:

Roll back the last changeset that was applied:

```sh
./gradlew rollbackCount -PliquibaseCommandValue=1
```

Using the following way we can add a rollback block in your changeset


## Liquibase limitations compared to other language migrations

I’ve spent a few years with Python/Flask using SQLAlchemy, where Alembic handled migrations. In that world, I didn’t have to spell out every change by hand Alembic could autogenerate upgrade/downgrade scripts from model diffs, assign version numbers, and let me roll back to a specific revision. Autogeneration wasn’t perfect, but with a thorough review it usually worked.

With Liquibase in a Spring/Gradle setup, the model is different. Liquibase is declarative and prefers explicit changesets. I can still use the Hibernate integration to diff my entities against the database and generate new changesets, but rollbacks aren’t fully auto-generated. Liquibase supports the rollback command, but it only works automatically when a change type is inherently reversible or when I provide an explicit <rollback> block. Because of that, I treat rollback content as something I author on purpose—that’s safer, but it feels less hands-off compared to Alembic. Also, to detect model changes from Java, I need the extra Gradle/Liquibase config (e.g., referenceUrl, liquibase-hibernate extension, and including compiled classes on the Liquibase classpath), which is a bit more setup than Alembic’s usual flow.
