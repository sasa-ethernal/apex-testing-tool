import { check, sleep } from 'k6';
import exec from 'k6/x/exec';

const vus = 415
const iters = 3
const T = 7
let vuData = {}

export const options = {
  // A number specifying the number of VUs to run concurrently.
  //vus: 300,
  // A string specifying the total duration of the test run.
  //duration: '50s',
  //iterations: 2,

  scenarios: {
    contacts: {
      executor: 'per-vu-iterations',
      vus: vus,
      iterations: iters,
      maxDuration: '10m',
    },
  },
};

// Perform setup tasks in the setup() function
export function setup() {
  exec.command("chmod", ["+x", "generate_address.sh"], {
    "dir": "scripts"
  });

  exec.command("chmod", ["+x", "fill_initial_addresses.sh"], {
    "dir": "scripts"
  });

  exec.command("chmod", ["+x", "send_one_tx.sh"], {
    "dir": "scripts"
  });

  exec.command("chmod", ["+x", "query_utxos_range.sh"], {
    "dir": "scripts"
  });
}

// The function that defines VU logic.
//
// See https://grafana.com/docs/k6/latest/examples/get-started-with-k6/ to learn more
// about authoring k6 scripts.
//
export default function () {

  // In 1st iteration generate address that will be filled by initial utxo
  if (__ITER === 0) {
    if (!vuData[__VU]) {
      vuData[__VU] = [];
    }

    let address = exec.command("bash", ["scripts/generate_address.sh", `iter${__ITER}vu${__VU}`]);

    // Log the output of the shell command
    //console.log(`Address: ${address}`);

    vuData[__VU].push(`iter${__ITER}vu${__VU}`);
  }

  sleep(1);

  // In case of 1st iteration fill initial addresses with funds
  if (__VU === 1 && __ITER === 0) {
    let startTime = Date.now();

    sleep(1)

    let commandOutput = exec.command("bash", ["scripts/fill_initial_addresses.sh", vus]);
    console.log(`Shell command output: ${commandOutput}`);

    let endTime = Date.now();
    let executionTime = endTime - startTime;
    if (T * 1000 - executionTime > 0) {
      sleep((T * 1000 - executionTime) / 1000)
    }
  } else if (__ITER === 0) {
    sleep(T)
  } else {

    // Send propagating tx
    //  __ITER:
    //           0          1            2           
    //  initial -> iter0vu1 -> iter1vu01 -> iter2vu101
    //                         iter0vu1  -> iter2vu01  ...

    let newSenders = []
    let digits;
    let result;
    let receiver;

    let retryCounter = 0;

    vuData[__VU].forEach(sender => {
      digits = sender.match(/\d+/g);
      result = digits.join("");
      receiver = `iter${__ITER}vu${result}`

      retryCounter = 0;

      let commandOutput;
      while (retryCounter < 10) {
        commandOutput = exec.command("bash", ["scripts/send_one_tx.sh", sender, receiver]);

        if (!isBlank(commandOutput)) {
          console.log(`From ${sender} to ${receiver} command output: ${commandOutput}`);
          newSenders.push(receiver)
          break;
        } else {
          console.error(`Retry transaction submission from ${sender} to ${receiver}`);
          retryCounter += 1;
          sleep(0.2);
        }
      }

      //if (retryCounter == 10) unssucessfullTx += 1;
      check(retryCounter, {
        'transaction passed': (r) => r !== 10,
      });
    });

    vuData[__VU] = vuData[__VU].concat(newSenders);
  }
}

// Perform teardown tasks after the test completes
export function teardown() {
  let commandOutput = exec.command("chmod", ["+x", "stop_cluster.sh"], {
    "dir": "scripts"
  });

  commandOutput = exec.command("bash", ["scripts/stop_cluster.sh"]);

  console.log(commandOutput);

  exec.command("rm", ["-rf", "cluster"])

  console.log('Teardown tasks executed');
}

function isBlank(str) {
  return (!str || /^\s*$/.test(str));
}
