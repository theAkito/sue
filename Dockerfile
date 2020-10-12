## This test suite covers all the original `gosu` test cases.
## https://github.com/tianon/gosu/blob/master/Dockerfile.test-alpine

FROM nimlang/nim:1.2.6-alpine as build

RUN apk add --no-cache git
RUN git clone https://github.com/theAkito/sue.git /root/sue
WORKDIR /root/sue
RUN nimble check
RUN nimble --accept install --depsOnly
RUN nimble fbuild

FROM alpine:3.12

RUN cut -d: -f1 /etc/group | xargs -n1 addgroup nobody
COPY --from=build /root/sue/sue /usr/local/bin/sue

ENV SUE=/usr/local/bin/sue

# For local testing, overwriting the previously built binary.
ENV LOCAL_BUILD=true
COPY sue /opt
RUN { [ $LOCAL_BUILD = true ] && \
    apk add --no-cache libc6-compat && \
    cp -a /opt/sue /usr/local/bin/sue; }

RUN { \
    echo '#!/bin/sh'; \
    echo 'set -x'; \
    echo; \
    echo 'spec="$1"; shift'; \
    echo; \
    echo 'expec="$1"; shift'; \
    echo 'real="$($SUE "$spec" id -u):$($SUE "$spec" id -g):$($SUE "$spec" id -G)"'; \
    echo '[ "$expec" = "$real" ]'; \
    echo; \
    echo 'expec="$1"; shift'; \
    echo 'real="$($SUE "$spec" id -un):$($SUE "$spec" id -gn):$($SUE "$spec" id -Gn)" || true'; \
    echo '[ "$expec" = "$real" ]'; \
  } > /usr/local/bin/sue-tester \
  && chmod +x /usr/local/bin/sue-tester

RUN chgrp nobody /usr/local/bin/sue
RUN chmod +s /usr/local/bin/sue
USER nobody
ENV HOME /omg/really/sue/nowhere
RUN sue-tester 0 "0:0:$(id -G root)" "root:root:$(id -Gn root)"
RUN sue-tester 0:0 '0:0:0' 'root:root:root'
RUN sue-tester root "0:0:$(id -G root)" "root:root:$(id -Gn root)"
RUN sue-tester 0:root '0:0:0' 'root:root:root'
RUN sue-tester root:0 '0:0:0' 'root:root:root'
RUN sue-tester root:root '0:0:0' 'root:root:root'
RUN sue-tester 1000 "1000:$(id -g):$(id -g)" "1000:$(id -gn):$(id -gn)"
RUN sue-tester 0:1000 '0:1000:1000' 'root:1000:1000'
RUN sue-tester 1000:1000 '1000:1000:1000' '1000:1000:1000'
RUN sue-tester root:1000 '0:1000:1000' 'root:1000:1000'
RUN sue-tester 1000:root '1000:0:0' '1000:root:root'
RUN sue-tester 1000:daemon "1000:$(id -g daemon):$(id -g daemon)" '1000:daemon:daemon'
RUN sue-tester games "$(id -u games):$(id -g games):$(id -G games)" 'games:games:games users'
RUN sue-tester games:daemon "$(id -u games):$(id -g daemon):$(id -g daemon)" 'games:daemon:daemon'

RUN sue-tester 0: "0:0:$(id -G root)" "root:root:$(id -Gn root)"
RUN sue-tester '' "$(id -u):$(id -g):$(id -G)" "$(id -un):$(id -gn):$(id -Gn)"
RUN sue-tester ':0' "$(id -u):0:0" "$(id -un):root:root"

RUN [ "$(sue 0 env | grep '^HOME=')" = 'HOME=/root' ]
RUN [ "$(sue 0:0 env | grep '^HOME=')" = 'HOME=/root' ]
RUN [ "$(sue root env | grep '^HOME=')" = 'HOME=/root' ]
RUN [ "$(sue 0:root env | grep '^HOME=')" = 'HOME=/root' ]
RUN [ "$(sue root:0 env | grep '^HOME=')" = 'HOME=/root' ]
RUN [ "$(sue root:root env | grep '^HOME=')" = 'HOME=/root' ]
RUN [ "$(sue 0:1000 env | grep '^HOME=')" = 'HOME=/root' ]
RUN [ "$(sue root:1000 env | grep '^HOME=')" = 'HOME=/root' ]
RUN [ "$(sue 1000 env | grep '^HOME=')" = 'HOME=/' ]
RUN [ "$(sue 1000:0 env | grep '^HOME=')" = 'HOME=/' ]
RUN [ "$(sue 1000:root env | grep '^HOME=')" = 'HOME=/' ]
RUN [ "$(sue games env | grep '^HOME=')" = 'HOME=/usr/games' ]
RUN [ "$(sue games:daemon env | grep '^HOME=')" = 'HOME=/usr/games' ]

RUN ! sue bogus true
RUN ! sue 0day true
RUN ! sue 0:bogus true
RUN ! sue 0:0day true

CMD [ "printf", "\n################################\n%s\n################################\n", "            SUCCESS!" ]