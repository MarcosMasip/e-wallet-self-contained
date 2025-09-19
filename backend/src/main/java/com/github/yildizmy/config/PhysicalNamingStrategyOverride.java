package com.github.yildizmy.config;

import org.hibernate.boot.model.naming.Identifier;
import org.hibernate.boot.model.naming.PhysicalNamingStrategy;
import org.hibernate.engine.jdbc.env.spi.JdbcEnvironment;

public class PhysicalNamingStrategyOverride implements PhysicalNamingStrategy {
    @Override
    public Identifier toPhysicalCatalogName(Identifier name, JdbcEnvironment context) { return name; }
    @Override
    public Identifier toPhysicalSchemaName(Identifier name, JdbcEnvironment context) { return name; }
    @Override
    public Identifier toPhysicalTableName(Identifier name, JdbcEnvironment context) {
        if (name != null && "user".equalsIgnoreCase(name.getText()) && isH2()) {
            return Identifier.toIdentifier("public_user");
        }
        return name;
    }
    @Override
    public Identifier toPhysicalSequenceName(Identifier name, JdbcEnvironment context) { return name; }
    @Override
    public Identifier toPhysicalColumnName(Identifier name, JdbcEnvironment context) { return name; }

    private boolean isH2() {
        String url = System.getProperty("spring.datasource.url", System.getenv("SPRING_DATASOURCE_URL"));
        return url != null && url.contains(":h2:");
    }
}
