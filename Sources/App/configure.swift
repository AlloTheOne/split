import Fluent
import FluentPostgresDriver
import JWT
import Vapor
import APNS

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.middleware.use(SessionsMiddleware(session: app.sessions.driver))
    

    if let databaseURL = Environment.get("DATABASE_URL") {
        var tlsConfig: TLSConfiguration = .makeClientConfiguration()
        tlsConfig.certificateVerification = .none
        let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)
        
        var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
        postgresConfig.coreConfiguration.tls = .require(nioSSLContext)
        
        app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
        
        
    } else {
       
        app.databases.use(
            .postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "sarabinkuddah",
            password: Environment.get("DATABASE_PASSWORD") ?? "",
            database: Environment.get("DATABASE_NAME") ?? "splie"
        ), as: .psql)
    }

    
   
    
    app.migrations.add(CreateUser())
    app.migrations.add(CreateLocation())
    app.migrations.add(CreateSTC())
    app.migrations.add(CreateBank())
    app.migrations.add(CreateToken())
    app.migrations.add(CreateOrder())
    app.migrations.add(CreateItem())
    app.migrations.add(CreateUser_Order())
    
    if app.environment == .development{
        try await app.autoMigrate().get()
    }
    

//    app.views.use(.leaf)

    

    // register routes
   
    try routes(app)
}
