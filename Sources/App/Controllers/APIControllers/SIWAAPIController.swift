//
//  SIWAAPIController.swift
//  
//
//  Created by Alaa Alabdullah on 10/05/2023.
//

import Fluent
import JWT
import Vapor
import APNS
struct SIWAAPIController {

  struct SIWARequestBody: Content {
    let firstName: String?
    let lastName: String?
    let appleIdentityToken: String
  }

  func authHandler(req: Request) throws -> EventLoopFuture<UserResponse> {
    let userBody = try req.content.decode(SIWARequestBody.self)

    return req.jwt.apple.verify(
      userBody.appleIdentityToken,
      applicationIdentifier: ProjectConfig.SIWA.applicationIdentifier
    ).flatMap { appleIdentityToken in
      User.findByAppleIdentifier(appleIdentityToken.subject.value, req: req)
        .flatMap { user in
          if user == nil {
            return SIWAAPIController.signUp(
              appleIdentityToken: appleIdentityToken,// if fn ln == nil restart or somth
              firstName: userBody.firstName,
              lastName: userBody.lastName,
              req: req
            )
          } else {
            return SIWAAPIController.signIn(
              appleIdentityToken: appleIdentityToken,
              firstName: userBody.firstName,
              lastName: userBody.lastName,
              req: req
            )
          }
        }
    }
  }

  static func signUp(
    appleIdentityToken: AppleIdentityToken,
    firstName: String? = nil,
    lastName: String? = nil,
    req: Request
  ) -> EventLoopFuture<UserResponse> {
    guard let email = appleIdentityToken.email else {
      return req.eventLoop.makeFailedFuture(UserError.siwaEmailMissing)
    }
    return User.assertUniqueEmail(email, req: req).flatMap {
      let user = User(
        email: email,
        firstName: firstName,
        lastName: lastName,
        appleUserIdentifier: appleIdentityToken.subject.value
      )
      return user.save(on: req.db)
        .flatMap {
          guard let accessToken = try? user.createAccessToken(req: req) else {
            return req.eventLoop.future(error: Abort(.internalServerError))
          }
            
          return accessToken.save(on: req.db)
            .flatMapThrowing { try .init(accessToken: accessToken, user: user) }
      }
    }
  }

  static func signIn(
    appleIdentityToken: AppleIdentityToken,
    firstName: String? = nil,
    lastName: String? = nil,
    req: Request
  ) -> EventLoopFuture<UserResponse> {
    User.findByAppleIdentifier(appleIdentityToken.subject.value, req: req)
      .unwrap(or: Abort(.notFound))
      .flatMap { user -> EventLoopFuture<User> in
        if let email = appleIdentityToken.email {
          user.email = email
          user.firstName = firstName
          user.lastName = lastName
          return user.update(on: req.db).transform(to: user)
        } else {
          return req.eventLoop.future(user)
        }
      }
      .flatMap { user in
        guard let accessToken = try? user.createAccessToken(req: req) else {
          return req.eventLoop.future(error: Abort(.internalServerError))
        }
        return accessToken.save(on: req.db)
          .flatMapThrowing { try .init(accessToken: accessToken, user: user) }
    }
  }
}

// MARK: - RouteCollection
extension SIWAAPIController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.post(use: authHandler)
    
  }
}
