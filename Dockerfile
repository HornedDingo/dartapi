FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline

EXPOSE 8888

# CMD ["dart", "bin/main.dart"]
# CMD ["dart", "run" ,"conduit", "db", "upgrade", "&&", "dart", "bin/main.dart"]
CMD ["/bin/sh", "-c", " dart run conduit db upgrade && dart bin/main.dart"]