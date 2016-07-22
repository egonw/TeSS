module TeSS
  module HasImage

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods

      def has_image(placeholder:)
        has_attached_file :image, styles: { media: "150x150>" }, default_url: placeholder

        validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/
        validates :image_url, url: true, allow_blank: true

        before_save :resolve_image_url
        include HasImage::InstanceMethods
      end

    end

    module InstanceMethods

      private

      def resolve_image_url
        unless self.image_url.blank?
          # Download the image from the given URL if no image file provided or if URL was changed.
          if !self.image? || self.image_url_changed?
            begin
              uri = URI.parse(self.image_url)
              self.image = uri
            rescue URI::InvalidURIError
            end
          elsif self.image.dirty? # Clear the URL if there was a file provided (as it won't match the file anymore)
            self.image_url = nil
          end
        end
      end
    end

  end

  ActiveRecord::Base.class_eval do
    include HasImage
  end
end
