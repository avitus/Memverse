# coding: utf-8

module PushNotification

  def ios_quiz_alert(msg)

    app_name = Rpush::Apns::App.find_by_name("Memverse_iOS")  # name of the mobile app

    Rails.logger.info("==== Sending push notifications ====")

    User.where(:quiz_alert => true).each { |u|
      if u.device_token && u.device_token.length == 64
        n               = Rpush::Apns::Notification.new
        n.app           = app_name
        n.device_token  = u.device_token # 64-character hex string
        n.alert         = msg
        n.save!
        Rails.logger.info("   Sent iOS push notification to #{u.email}")
      end
    }

    Rpush.push  # send all push notifications

  end

  # Not yet using this
  def mobile_reminder(msg, user_id)

    app_name = Rpush::Apns::App.find_by_name("Memverse_iOS")  # name of the mobile app

    u = User.find(user_id)

    if u.device_token && u.device_token.length == 64
      n               = Rpush::Apns::Notification.new
      n.app           = app_name
      n.device_token  = u.device_token # 64-character hex string
      n.alert         = msg
      n.save!
      Rails.logger.info("   Sent iOS reminder push notification to #{u.email}")
    else
      Rails.logger.info("   Invalide device token for push notification for #{u.email}")
    end    

    Rpush.push  # send all push notifications

  end

end