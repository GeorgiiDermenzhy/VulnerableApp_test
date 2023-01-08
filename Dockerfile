FROM openjdk:12-jdk-alpine
WORKDIR /usr/src/app/
COPY . .
CMD ["java" "-jar" "VulnerableApp-1.0.0.jar"]
