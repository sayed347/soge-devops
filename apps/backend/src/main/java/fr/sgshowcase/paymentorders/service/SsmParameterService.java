package fr.sgshowcase.paymentorders.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.ssm.SsmClient;
import software.amazon.awssdk.services.ssm.model.GetParameterRequest;

/**
 * Reads a config value from SSM Parameter Store (demonstrates task role + VPC
 * endpoint + KMS in AWS). Falls back gracefully to "local" when SSM is
 * unreachable, e.g. when running via docker-compose without AWS credentials.
 */
@Service
public class SsmParameterService {

    private static final Logger log = LoggerFactory.getLogger(SsmParameterService.class);
    private static final String FALLBACK_VALUE = "local";

    private final String parameterName;
    private final SsmClient ssmClient;

    public SsmParameterService(@Value("${app.ssm.parameter-name}") String parameterName) {
        this.parameterName = parameterName;
        // Explicit region so client creation never fails locally for lack of one;
        // credential resolution stays lazy and is caught in fetchInfoMessage().
        String region = System.getenv().getOrDefault("AWS_REGION", "eu-west-3");
        this.ssmClient = SsmClient.builder().region(Region.of(region)).build();
    }

    public String fetchInfoMessage() {
        try {
            GetParameterRequest request = GetParameterRequest.builder()
                    .name(parameterName)
                    .withDecryption(true)
                    .build();
            return ssmClient.getParameter(request).parameter().value();
        } catch (Exception ex) {
            log.warn("SSM parameter '{}' unreachable, falling back to '{}': {}",
                    parameterName, FALLBACK_VALUE, ex.getMessage());
            return FALLBACK_VALUE;
        }
    }
}
