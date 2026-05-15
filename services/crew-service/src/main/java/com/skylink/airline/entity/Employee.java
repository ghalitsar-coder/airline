package com.skylink.airline.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

@Entity
@Table(name = "employees")
public class Employee extends PanacheEntityBase {

    @Id
    @Column(name = "employee_id")
    public UUID employeeId;

    @Column(name = "employee_number", nullable = false, unique = true)
    public String employeeNumber;

    @Column(name = "first_name")
    public String firstName;

    @Column(name = "last_name")
    public String lastName;

    @Column(name = "email", nullable = false, unique = true)
    public String email;

    public static Employee findByEmployeeId(UUID employeeId) {
        return findById(employeeId);
    }
}
