package com.github.yildizmy.dto.mapper;

import com.github.yildizmy.dto.request.SignupRequest;
import com.github.yildizmy.domain.entity.Role;
import com.github.yildizmy.domain.enums.RoleType;
import com.github.yildizmy.domain.entity.User;
import com.github.yildizmy.service.RoleService;
import org.mapstruct.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Mapper used for mapping SignupRequest fields.
 */
@Mapper(componentModel = "spring",
        uses = {PasswordEncoder.class, RoleService.class},
        injectionStrategy = InjectionStrategy.CONSTRUCTOR)
public abstract class SignupRequestMapper {

    private PasswordEncoder passwordEncoder;
    private RoleService roleService;

    @Autowired
    public void setPasswordEncoder(PasswordEncoder passwordEncoder) {
        this.passwordEncoder = passwordEncoder;
    }

    @Autowired
    public void setRoleService(RoleService roleService) {
        this.roleService = roleService;
    }

    @Mapping(target = "firstName", expression = "java(org.apache.commons.text.WordUtils.capitalizeFully(dto.getFirstName()))")
    @Mapping(target = "lastName", expression = "java(org.apache.commons.text.WordUtils.capitalizeFully(dto.getLastName()))")
    @Mapping(target = "username", expression = "java(dto.getUsername().trim().toLowerCase())")
    @Mapping(target = "email", expression = "java(dto.getEmail().trim().toLowerCase())")
    @Mapping(target = "password", ignore = true)
    @Mapping(target = "roles", ignore = true)
    public abstract User toUser(SignupRequest dto);

    @AfterMapping
    void setToEntityFields(@MappingTarget User entity, SignupRequest dto) {
        entity.setPassword(passwordEncoder.encode(dto.getPassword()));
    // Defensive: if client sends null/empty roles, default to ROLE_USER
    final var requestedRoles = (dto.getRoles() == null || dto.getRoles().isEmpty())
        ? Set.of(RoleType.ROLE_USER.name())
        : dto.getRoles();

    List<RoleType> roleTypes = requestedRoles.stream()
        .map(RoleType::valueOf)
        .toList();

    List<Role> roles = roleService.getReferenceByTypeIsIn(new HashSet<>(roleTypes));

    // If for any reason resolution produced no roles (e.g., missing DB rows), force ROLE_USER fallback
    if (roles.isEmpty()) {
        roles = roleService.getReferenceByTypeIsIn(Set.of(RoleType.ROLE_USER));
    }

    entity.setRoles(new HashSet<>(roles));
    }
}
