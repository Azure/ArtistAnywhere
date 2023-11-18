function StartProcess {
  command="$1"
  logFile=$2
  $command 1>> $logFile.out 2>> $logFile.err
  cat $logFile.err
}

function FileExists {
  filePath=$1
  [ -f $filePath ]
}

function InitializeClient {
  enableWeka=$1
  StartProcess deadlinecommand "-ChangeRepository Direct /mnt/deadline" $binDirectory/deadline-repository
  if [ $enableWeka == true ]; then
    curl http://content.artist.studio:14000/dist/v1/install | sh
  fi
}
