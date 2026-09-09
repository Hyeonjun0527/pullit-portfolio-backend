package kr.it.pullit.platform.security;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import kr.it.pullit.platform.security.config.AuthorizationRules;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.test.context.junit.jupiter.web.SpringJUnitWebConfig;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

@SpringJUnitWebConfig(AuthorizationRulesTest.TestConfig.class)
class AuthorizationRulesTest {

  @Autowired private WebApplicationContext context;
  private MockMvc mockMvc;

  @BeforeEach
  void setUp() {
    mockMvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
  }

  @ParameterizedTest
  @ValueSource(strings = {"/api-docs", "/api-docs/swagger-config", "/api-docs.yaml"})
  void anonymousUsersCanReadApiDocumentation(String path) throws Exception {
    mockMvc.perform(get(path)).andExpect(status().isOk());
  }

  @ParameterizedTest
  @ValueSource(strings = {"/api/private", "/api/admin/private", "/api-docs-private"})
  void privateEndpointsStillRequireAuthentication(String path) throws Exception {
    mockMvc.perform(get(path)).andExpect(status().isUnauthorized());
  }

  @Test
  void ordinaryMembersCannotAccessAdminEndpoints() throws Exception {
    mockMvc
        .perform(get("/api/admin/private").with(user("member").roles("MEMBER")))
        .andExpect(status().isForbidden());
  }

  @Configuration
  @EnableWebSecurity
  @EnableWebMvc
  static class TestConfig {
    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
      return http.authorizeHttpRequests(AuthorizationRules.authenticated())
          .exceptionHandling(
              exceptions ->
                  exceptions.authenticationEntryPoint(
                      new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
          .build();
    }

    @Bean
    TestController testController() {
      return new TestController();
    }
  }

  @RestController
  static class TestController {
    @GetMapping({"/api-docs", "/api-docs/swagger-config", "/api-docs.yaml"})
    String apiDocumentation() {
      return "{}";
    }
  }
}
