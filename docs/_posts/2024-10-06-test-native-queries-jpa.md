---
layout: post
title:  "Testing Native Queries with Functions in Spring Boot with JPA and H2"
tags: java jpa springboot h2
categories: java jpa springboot h2
image: /assets/test-native-queries-jpa.png
---
![Test Native Queries JPA](/assets/test-native-queries-jpa.png)

Spring Boot gives you the facility of testing your repositories using H2, an embedded in-memory database that can emulate other database's dialects. It's a handy feature, but with limitations. One of these limitations is the fact that H2 doesn't emulate the full range of existing functions in other databases.
Then, say you find yourself wanting to execute the query bellow on Microsoft SQL Server using JPA native query functionality, and map the projection to a POJO:

```sql
-- MS SQL Server has a FORMAT function for dates, H2 doesn't
SELECT 
  FORMAT(tbl.TIMESTAMP, 'yyyy-MM-dd') as date, 
  count(*) as count,
  tbl.COUNTRY as value
FROM
  ORDERS tbl
GROUP BY
  FORMAT(tbl.TIMESTAMP, 'yyyy-MM-dd'), tbl.COUNTRY;
```

This will run just fine on SQL Server, but it will fail on H2 because the function FORMAT doesn't exist there. The usual solution would be to either point your tests to a real SQL Server instance, not ideal if you're running it on a CI server or if you want to keep the external dependencies to a minimum, or you just skip testing it, again not the best solution.
But there's a third option, H2 lets you define your own functions, using Java code. And Spring Boot will happily execute any script you put in the `src/test/resources/data.sql` file before running your tests.
The script bellows shows a very simple implementation of the FORMAT function, that emulates just enough the native SQL Server version that's enough to run my unit tests.

```sql
-- src/test/resources/data.sql
create alias FORMAT as $$
import java.util.Date;
import java.text.SimpleDateFormat;
@CODE
String format(Date date, String format) {
    return new SimpleDateFormat(format).format(date);
}
$$;
```

Hope this can save somebody else a few hours of internet searching, and fumbling around with Spring Boot and H2 documentation.