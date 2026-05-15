package com.skylink.airline.service;

import com.skylink.airline.entity.RevenueAccounting;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;

@ApplicationScoped
public class RevenueService {

    public List<RevenueAccounting> listAll() {
        return RevenueAccounting.listAll();
    }
}
