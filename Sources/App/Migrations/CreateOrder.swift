//
//  CreateOrder.swift
//  
//
//  Created by Alaa Alabdullah on 04/05/2023.
//

import Fluent

struct CreateOrder: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Order.schema)
            .id()
            .field("locationID", .uuid, .required, .references("locations", "id"))
            .field("merchant_name", .string, .required)
            .field("app_name", .string, .required)
            .field("delivery_fee", .double, .required)
            .field("checkpoint", .string, .required)
            .field("notes", .string)
            .field("active", .bool, .sql(.default(true)))
            .field("status", .string)
            .field("updatedAt", .string)
            .field("createdAt", .string)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Order.schema).delete()
    }
}
