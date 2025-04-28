package com.example.bookorderapp.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests((requests) -> requests
                .anyRequest().authenticated()
            )
            .httpBasic()
            .and()
            .formLogin().disable()
            .csrf().disable(); // Disabling CSRF for simplicity, but consider this for production

        return http.build();
    }

    @Bean
    public UserDetailsService users() {
        // This is for demonstration purposes only. Use a secure way to manage users in production.
        UserDetails user = User.builder()
            .username("user")
            .password("{noop}password") // {noop} indicates no password encoding (not secure for production)
            .roles("USER")
            .build();
        return new InMemoryUserDetailsManager(user);
    }
}
