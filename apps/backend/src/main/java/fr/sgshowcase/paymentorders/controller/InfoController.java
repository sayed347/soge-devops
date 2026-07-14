package fr.sgshowcase.paymentorders.controller;

import fr.sgshowcase.paymentorders.dto.InfoResponse;
import fr.sgshowcase.paymentorders.service.SsmParameterService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class InfoController {

    private final SsmParameterService ssmParameterService;
    private final String version;
    private final String environment;

    public InfoController(SsmParameterService ssmParameterService,
                           @Value("${app.version}") String version,
                           @Value("${app.environment}") String environment) {
        this.ssmParameterService = ssmParameterService;
        this.version = version;
        this.environment = environment;
    }

    @GetMapping("/api/info")
    public InfoResponse info() {
        return new InfoResponse(version, environment, ssmParameterService.fetchInfoMessage());
    }
}
