pipeline {
    agent any
    parameters{
        booleanParam(name: 'executeTests',defaultValue: true, description: 'Run SCA, SAST, DAST tests')
        booleanParam(name: 'scanImage',defaultValue: true, description: 'Scun Image')
    }
    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker_hub_login')
    }
    stages {
        stage('Build') {
            steps {
                echo 'Running build automation'
                sh './gradlew bootJar'
                archiveArtifacts artifacts: 'src/', followSymlinks: false
            }
        }
        stage('SCA with Dependency-Check') {
            when{
                expression{
                    params.executeTests
                }
            }
            steps {
                dependencyCheck additionalArguments: '', odcInstallation: 'dependency-check7.3.0'
                dependencyCheckPublisher pattern: ''
            }
        }
        stage('SAST with Semgrep-Scan') {
            when{
                expression{
                    params.executeTests
                }
            }
            steps {
                sh 'docker run --rm -v "${PWD}:/src" returntocorp/semgrep semgrep --config=auto'
            }
        }
        stage('Image Scan: Trivy') {
            when{
                expression{
                    params.scanImage
                }
            }
            steps {
                sh 'trivy image georgeder/vulnerableapp:latest'
            }
        }
        stage('Build Docker Image') {
            steps {
                    sh './gradlew bootBuildImage --imageName=georgeder/vulnerableapp:latest'
            }
        }
        stage('Push Docker Image') {
            steps {
                sh "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"
                sh 'docker push georgeder/vulnerableapp:latest' 
            }
        }
        stage('DeployToProduction') {
            steps {
                input 'Deploy to Production?'
                milestone(1)
                kubernetesDeploy(
                    kubeconfigId: 'kubeconfig',
                    configs: 'vulnerableapp.yml',
                    enableConfigSubstitution: true
                )
            }
        }
        stage('DAST with OWASP ZAP'){
            when{
                expression{
                    params.executeTests
                }
            }
            steps{
                sh 'docker run -v "${PWD}:/zap/wrk/:rw" -t owasp/zap2docker-weekly zap-baseline.py -t http://10.0.0.11:32000/VulnerableApp/ -j --auto'
            }
        }
    }
}
