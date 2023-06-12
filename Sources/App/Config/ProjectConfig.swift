//
//  ProjectConfig.swift
//  
//
//  Created by Alaa Alabdullah on 09/05/2023.
//

import Vapor

struct ProjectConfig {
  struct AccessToken {
    static let expirationTime: TimeInterval = 120 * 24 * 60 * 60 // 30 days - 1 day
  }

  struct SIWA {
    static let applicationIdentifier = Environment.get("SIWA_APPLICATION_IDENTIFIER")! //e.g.
                       
      //com.raywenderlich.siwa-vapor
    static let servicesIdentifier = Environment.get("SIWA_SERVICES_IDENTIFIER")! //e.g. com.raywenderlich.siwa-vapor.services
    static let redirectURL = Environment.get("SIWA_REDIRECT_URL")! // e.g. https://foobar.ngrok.io/web/auth/siwa/callback
  }
}
