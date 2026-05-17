FROM jekyll/jekyll:pages

WORKDIR /srv/jekyll

# Install build dependencies for native extensions
RUN apk add --no-cache build-base

# Install Ruby dependencies once at image build time.
COPY Gemfile Gemfile.lock ./
RUN bundle config set path '/usr/local/bundle'     && bundle install

COPY . .

EXPOSE 4000

# Default command serves the site; override with `jekyll build` when needed.
CMD ["jekyll", "serve", "--host", "0.0.0.0", "--port", "4000", "--livereload", "--force_polling"]
