#Requires -RunAsAdministrator
# Simple static http server.
Param(
    [int]$port = 5001,
    [string]$root = "C:\webserver\"
)

function Serve {
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add("http://+:$port/")
    Write-Host "Root: $root"
    try {
        $listener.Start()
        Write-Host "server started on :$port"
        while ($listener.IsListening) {
            $context = $null
            $ctxTask = $listener.GetContextAsync()
            do {
                if ($ctxTask.Wait(100)) {
                    $context = $ctxTask.Result
                }
            }
            while (-not $context)

            Handle $context
        }

    } 
    catch [System.Exception] {
        Write-Host $_
    }
    finally {
        $listener.Stop()
    }
}

function Handle([System.Net.HttpListenerContext] $context) {
    try {
        Write-Host $context.Request.RawUrl

        $context.Request.HttpMethod
        $context.Request.Url
        $context.Request.Headers.ToString() # pretty printing with .ToString()
        $requestBodyReader = New-Object System.IO.StreamReader $context.Request.InputStream
        $bodytxt = $requestBodyReader.ReadToEnd()

        if($bodytxt -like '*apppool*')
        {
            Write-Host("apppool")
        

        $path = $context.Request.RawUrl.TrimStart("/")

        if ([String]::IsNullOrWhiteSpace($path)) {
            $iispools = Get-IISAppPool
            $iispoolsname1 = $iispools[0].Name.ToString()
            $iispoolsstate1 = $iispools[0].State.ToString()
            $iispoolsautostart1 = $iispools[0].AutoStart.toString()
    
            $iispoolsname2 = $iispools[1].Name.ToString()
            $iispoolsstate2 = $iispools[1].State.ToString()
            $iispoolsautostart2 = $iispools[1].AutoStart.toString()

$context.Response.StatusCode = 200
$context.Response.ContentType = 'application/json'

$responseJson = @"
{
  "type": "message",
  "attachments": [
        {
              "contentType": "application/vnd.microsoft.card.adaptive",
      "contentUrl": null,
      "content": {
        "type": "AdaptiveCard",
        "version": "1.4",
        "body": [
          {
            "type": "TextBlock",
            "text": "App Pool:  $iispoolsname1, $iispoolsstate1"

          },
          {
            "type": "TextBlock",
            "text": "App Pool:  $iispoolsname2, $iispoolsstate1"

          }
        ],
        "name": null,
        "thumbnailUrl": null
}}
  ]
}
"@

$responseBytes = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
$context.Response.OutputStream.Write($responseBytes, 0, $responseBytes.Length)


        
        }
        #$path = [System.IO.Path]::Combine($root, $path)
        #if ([System.IO.File]::Exists($path)) {
            #$fstream = [System.IO.FileStream]::new($path, [System.IO.FileMode]::Open)
            #$fstream.CopyTo($context.Response.OutputStream)
        #} else {
        #    $context.Response.StatusCode = 404
        #}
    }
    }
    catch [System.Exception] {
        $context.Response.StatusCode = 500
        Write-Error $_
    }
    finally {
        $context.Response.Close()
    }
}

Serve