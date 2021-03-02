module Scimitar
  module Schema
    # Represents the schema for the User resource
    # @see Scimitar::Resources::User
    class User < Base

      def initialize(options = {})
        super(name: 'User',
              id: self.class.id,
              description: 'Represents a User',
              scim_attributes: self.class.scim_attributes)

      end

      def self.id
        'urn:ietf:params:scim:schemas:core:2.0:User'
      end

      def self.scim_attributes
        [
          Attribute.new(name: 'userName',          type: 'string', uniqueness: 'server', required: true),

          Attribute.new(name: 'name', complexType: Scimitar::ComplexTypes::Name),

          Attribute.new(name: 'displayName',       type: 'string'),
          Attribute.new(name: 'nickName',          type: 'string'),
          Attribute.new(name: 'profileUrl',        type: 'string'),
          Attribute.new(name: 'title',             type: 'string'),
          Attribute.new(name: 'userType',          type: 'string'),
          Attribute.new(name: 'preferredLanguage', type: 'string'),
          Attribute.new(name: 'locale',            type: 'string'),
          Attribute.new(name: 'timezone',          type: 'string'),

          Attribute.new(name: 'active',            type: 'boolean'),

          Attribute.new(name: 'password',          type: 'string', mutability: 'writeOnly', returned: 'never'),

          Attribute.new(name: 'emails',           multiValued: true, complexType: Scimitar::ComplexTypes::Email),
          Attribute.new(name: 'phoneNumbers',     multiValued: true, complexType: Scimitar::ComplexTypes::PhoneNumber),
          Attribute.new(name: 'ims',              multiValued: true, complexType: Scimitar::ComplexTypes::Ims),
          Attribute.new(name: 'addresses',        multiValued: true, complexType: Scimitar::ComplexTypes::Address),
          Attribute.new(name: 'groups',           multiValued: true, complexType: Scimitar::ComplexTypes::Reference, mutability: 'immutable'),
          Attribute.new(name: 'entitlements',     multiValued: true, complexType: Scimitar::ComplexTypes::Entitlement),
          Attribute.new(name: 'roles',            multiValued: true, complexType: Scimitar::ComplexTypes::Role),
          Attribute.new(name: 'x509Certificates', multiValued: true, complexType: Scimitar::ComplexTypes::X509Certificate),
        ]
      end

    end
  end
end
