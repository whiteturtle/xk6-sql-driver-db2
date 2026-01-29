# xk6-sql-driver-db2

Database driver extension for [xk6-sql](https://github.com/grafana/xk6-sql) k6 extension to support IBM DB2 database.

## Example

```JavaScript file=examples/example.js
import sql from "k6/x/sql";
import driver from "k6/x/sql/driver/go_ibm_db";
// Required as the DB2 driver seems to return uint arrays for VARCHAR columns
import { TextDecoder } from "k6/x/encoding";

const con =
  "HOSTNAME=localhost;DATABASE=sample;PORT=50000;UID=db2inst1;PWD=password123";
const db = sql.open(driver, con);

export function setup() {
  let exist = db.query(
    "SELECT 1 FROM SYSCAT.TABLES WHERE TABSCHEMA='DB2INST1' AND TABNAME='SAMPLE';",
  );

  if (exist.length != 0) {
    db.exec("drop table SAMPLE;");
  }
  db.exec(`
     CREATE TABLE SAMPLE (
            id VARCHAR(10) NOT NULL DEFAULT '',
            f_name VARCHAR(40),
            l_name VARCHAR(40)
      );
  `);
}

export function teardown() {
  db.close();
}

export default function () {
  const streamDecoder = new TextDecoder();
  let result = db.exec(`
    INSERT INTO SAMPLE
      (id, f_name, l_name)
    VALUES
      ('1', 'Peter', 'Pan'),
      ('2', 'Wendy', 'Darling'),
      ('3', 'Tinker', 'Bell'),
      ('4', 'James', 'Hook');
  `);
  console.log(`${result.rowsAffected()} rows inserted`);

  let rows = db.query("SELECT * FROM SAMPLE WHERE f_name = 'Peter';");
  for (const row of rows) {
    console.log(streamDecoder.decode(new Uint8Array(row.L_NAME)));
  }
}
```

## Build Instructions

### Prerequisites

- Go 1.24 or higher
- [xk6](https://github.com/grafana/xk6) installed (`go install go.k6.io/xk6/cmd/xk6@latest`)
- IBM DB2 CLI driver (will be installed automatically)

### Building with Make (Recommended)

```bash
# Install IBM DB2 CLI driver
make setup-db2

# Build k6 with DB2 extension
make k6
```

This will:
1. Download and install the IBM DB2 CLI driver to `../../clidriver`
2. Build k6 with the DB2 extension at `./k6`

### Building with xk6 directly

```bash
# Install IBM DB2 CLI driver
make setup-db2

# Set required environment variables
export IBM_DB_HOME=${PWD}/../../clidriver
export CGO_CFLAGS=-I${PWD}/../../clidriver/include
export CGO_LDFLAGS=-L${PWD}/../../clidriver/lib
export DYLD_LIBRARY_PATH=${PWD}/../../clidriver/lib  # macOS
# OR for Linux:
# export LD_LIBRARY_PATH=${PWD}/../../clidriver/lib

export CGO_ENABLED=1

# Build k6
xk6 build \
  --with github.com/grafana/xk6-sql@latest \
  --with github.com/oleiade/xk6-encoding@latest \
  --with github.com/whiteturtle/xk6-sql-driver-db2=.
```

## Usage

### Running k6

Due to the DB2 CLI driver dependency, you need to set the library path when running k6:

```bash
# macOS
export DYLD_LIBRARY_PATH=${PWD}/../../clidriver/lib
./k6 run examples/example.js

# OR use the wrapper script
./run-k6.sh run examples/example.js
```

For Linux, use `LD_LIBRARY_PATH` instead of `DYLD_LIBRARY_PATH`.

Check the [xk6-sql documentation](https://github.com/grafana/xk6-sql) on how to use this database driver.

## Docker Usage

### Building the Docker image

```bash
docker build -t xk6-sql-db2:latest .
```

### Running with Docker

```bash
# Run a k6 script
docker run --rm -v $(pwd)/examples:/scripts xk6-sql-db2:latest run /scripts/example.js

# Check version
docker run --rm xk6-sql-db2:latest version

# Run with environment variables for DB connection
docker run --rm \
  -e DB_HOST=your-db-host \
  -e DB_PORT=50000 \
  -e DB_NAME=sample \
  -e DB_USER=db2inst1 \
  -e DB_PASSWORD=password \
  -v $(pwd)/examples:/scripts \
  xk6-sql-db2:latest run /scripts/example.js
```

### Kubernetes Usage

Example Kubernetes Job:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: k6-load-test
spec:
  template:
    spec:
      containers:
      - name: k6
        image: xk6-sql-db2:latest
        command: ["k6", "run", "/scripts/example.js"]
        volumeMounts:
        - name: scripts
          mountPath: /scripts
        env:
        - name: DB_HOST
          value: "your-db2-service"
        - name: DB_PORT
          value: "50000"
        - name: DB_NAME
          value: "sample"
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db2-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db2-credentials
              key: password
      volumes:
      - name: scripts
        configMap:
          name: k6-scripts
      restartPolicy: Never
  backoffLimit: 0
```
