# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

if Rails.env.development?
  guest_email = ENV["GUEST_USER_EMAIL"].presence || ENV["GUEST_USER_EMAL"].presence || "guest@example.com"
  guest_password = ENV["GUEST_USER_PASSWORD"].presence || "password123"

  guest_user = User.find_or_initialize_by(email: guest_email)
  guest_user.name ||= "Guest Sample User"
  guest_user.confirmed_at ||= Time.current
  guest_user.password = guest_password if guest_user.new_record? || guest_user.encrypted_password.blank?
  guest_user.password_confirmation = guest_password if guest_user.new_record? || guest_user.encrypted_password.blank?
  guest_user.save!

  sample_books = [
    {
      isbn: "9781001001001",
      title: "Bokrium Starter Guide",
      author: "Bokrium",
      publisher: "Bokrium",
      page: 48,
      price: 0,
      status: :reading,
      book_cover: "https://placehold.co/400x600/png?text=Bokrium+Starter",
      affiliate_url: nil
    },
    {
      isbn: "9780132350884",
      title: "Clean Code",
      author: "Robert C. Martin",
      publisher: "Prentice Hall",
      page: 464,
      price: 5280,
      status: :want_to_read,
      book_cover: "https://covers.openlibrary.org/b/isbn/9780132350884-L.jpg",
      affiliate_url: "https://www.google.com/search?tbm=bks&q=isbn:9780132350884"
    },
    {
      isbn: "9780134757599",
      title: "Refactoring (2nd Edition)",
      author: "Martin Fowler",
      publisher: "Addison-Wesley",
      page: 448,
      price: 6600,
      status: :reading,
      book_cover: "https://covers.openlibrary.org/b/isbn/9780134757599-L.jpg",
      affiliate_url: "https://www.google.com/search?tbm=bks&q=isbn:9780134757599"
    },
    {
      isbn: "9780135957059",
      title: "The Pragmatic Programmer (20th Anniversary Edition)",
      author: "Andrew Hunt, David Thomas",
      publisher: "Addison-Wesley",
      page: 352,
      price: 4950,
      status: :finished,
      book_cover: "https://covers.openlibrary.org/b/isbn/9780135957059-L.jpg",
      affiliate_url: "https://www.google.com/search?tbm=bks&q=isbn:9780135957059"
    },
    {
      isbn: "9780201633610",
      title: "Design Patterns",
      author: "Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides",
      publisher: "Addison-Wesley",
      page: 416,
      price: 4950,
      status: :want_to_read,
      book_cover: "https://covers.openlibrary.org/b/isbn/9780201633610-L.jpg",
      affiliate_url: "https://www.google.com/search?tbm=bks&q=isbn:9780201633610"
    },
    {
      isbn: "9780735619678",
      title: "Code Complete (2nd Edition)",
      author: "Steve McConnell",
      publisher: "Microsoft Press",
      page: 960,
      price: 6380,
      status: :reading,
      book_cover: "https://covers.openlibrary.org/b/isbn/9780735619678-L.jpg",
      affiliate_url: "https://www.google.com/search?tbm=bks&q=isbn:9780735619678"
    },
    {
      isbn: "9780321125217",
      title: "Domain-Driven Design",
      author: "Eric Evans",
      publisher: "Addison-Wesley",
      page: 560,
      price: 6380,
      status: :finished,
      book_cover: "https://covers.openlibrary.org/b/isbn/9780321125217-L.jpg",
      affiliate_url: "https://www.google.com/search?tbm=bks&q=isbn:9780321125217"
    },
    {
      isbn: "9780131177055",
      title: "Working Effectively with Legacy Code",
      author: "Michael C. Feathers",
      publisher: "Prentice Hall",
      page: 456,
      price: 5280,
      status: :want_to_read,
      book_cover: "https://covers.openlibrary.org/b/isbn/9780131177055-L.jpg",
      affiliate_url: "https://www.google.com/search?tbm=bks&q=isbn:9780131177055"
    },
    {
      isbn: "9780201835953",
      title: "The Mythical Man-Month",
      author: "Frederick P. Brooks Jr.",
      publisher: "Addison-Wesley",
      page: 336,
      price: 3520,
      status: :finished,
      book_cover: "https://covers.openlibrary.org/b/isbn/9780201835953-L.jpg",
      affiliate_url: "https://www.google.com/search?tbm=bks&q=isbn:9780201835953"
    },
    {
      isbn: "9780321965516",
      title: "Don't Make Me Think, Revisited",
      author: "Steve Krug",
      publisher: "New Riders",
      page: 216,
      price: 3520,
      status: :reading,
      book_cover: "https://covers.openlibrary.org/b/isbn/9780321965516-L.jpg",
      affiliate_url: "https://www.google.com/search?tbm=bks&q=isbn:9780321965516"
    },
    {
      isbn: "9780988262591",
      title: "The Phoenix Project",
      author: "Gene Kim, Kevin Behr, George Spafford",
      publisher: "IT Revolution Press",
      page: 432,
      price: 3300,
      status: :want_to_read,
      book_cover: "https://covers.openlibrary.org/b/isbn/9780988262591-L.jpg",
      affiliate_url: "https://www.google.com/search?tbm=bks&q=isbn:9780988262591"
    }
  ]

  sample_books.each do |attrs|
    book = guest_user.books.find_or_initialize_by(isbn: attrs.fetch(:isbn))
    book.assign_attributes(attrs.except(:isbn))
    book.save!
  end

  puts "[seed] guest sample bookshelf upserted for #{guest_email} (#{sample_books.size} books)"
else
  puts "[seed] skipped guest sample bookshelf seeding in #{Rails.env}"
end
