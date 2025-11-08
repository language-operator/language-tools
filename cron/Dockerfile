FROM git.theryans.io/language-operator/base:latest

USER root
RUN apk add --no-cache ruby ruby-dev ruby-bundler build-base ca-certificates

WORKDIR /app
COPY Gemfile /app/
RUN bundle install --no-cache

WORKDIR /mcp
COPY tools/ /mcp/
RUN chown -R langop:langop /mcp

USER langop
EXPOSE 80
ENV PORT=80 RACK_ENV=production

CMD ["ruby", "-r", "language_operator/tool_loader", "-e", "LanguageOperator::ToolLoader.start"]
