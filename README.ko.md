<p align="center">
  <a href="https://github.com/EasyDevv/set-sunshine-moonlight">
    <img src="./static/logo.webp" alt="Set Sunshine Moonlight 로고" width="240">
  </a>
</p>

<h1 align="center">Set Sunshine Moonlight</h1>

<p align="center">Tailscale 네트워크를 통해 게임 스트리밍을 할 수 있도록 <a href="https://app.lizardbyte.dev/Sunshine">Sunshine</a>, <a href="https://moonlight-stream.org">Moonlight</a>, <a href="https://tailscale.com">Tailscale</a>을 설치하고 구성하는 Windows 설정 스크립트입니다.</p>

<p align="center">
  <a href="README.md">English</a> |
  <a href="README.ko.md">한국어</a>
</p>

## 기능

- **Chocolatey**를 통해 Sunshine, Moonlight, Tailscale 설치
- Server, Client, Server and Client 역할 선택 지원
- `-Role` 플래그를 통한 설치 역할 자동 선택 지원
- Client 설정 시 Sunshine 서버의 Tailscale IP 주소 입력 안내
- 필요에 따라 로컬 또는 원격 Sunshine 웹 UI 자동 열기
- Client 설정이 포함되면 Moonlight 실행
- 관리 대상 패키지 전체 제거 지원

## 요구 사항

- Windows 10/11
- Client 모드에서는 동일한 Tailscale 네트워크에서 [Sunshine](https://app.lizardbyte.dev/Sunshine)이 실행 중인 서버 컴퓨터
- 관리자 권한 PowerShell

## 빠른 시작 (직접 실행)

GitHub에서 직접 최신 버전을 다운로드 없이 실행:

**CMD**
```cmd
powershell -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/EasyDevv/set-sunshine-moonlight/main/scripts/windows/set-windows.ps1')))"
```

**PowerShell**
```powershell
& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/EasyDevv/set-sunshine-moonlight/main/scripts/windows/set-windows.ps1')))
```

> Windows 표시 언어가 한국어면 메시지가 한국어로 출력되고, 그 외에는 영어로 출력됩니다.

## 사용 방법

### 패키지 매니저

이 스크립트는 **Chocolatey**를 사용하여 패키지를 설치합니다. Chocolatey는 winget보다 안정적입니다. winget은 기기에 따라 설치 설정이 복잡한 반면, Chocolatey는 대부분의 Windows에서 안정적으로 설치됩니다.

### 대화형 모드

인수 없이 실행하면 대화형 메뉴가 나타납니다:

```powershell
.\set-windows.ps1
```

1. 방향키로 **Install** 또는 **Uninstall** 선택
2. **Install**을 선택했다면 **Server**, **Client**, **Server and Client** 중 하나 선택

### 명령줄 모드

설치:

```powershell
.\set-windows.ps1 -Install -Role Server
```

Sunshine 서버 주소를 미리 알고 있는 Client 설치:

```powershell
.\set-windows.ps1 -Install -Role Client -Url "100.x.x.x"
```

서버와 클라이언트를 함께 설치:

```powershell
.\set-windows.ps1 -Install -Role ServerAndClient
```

제거:

```powershell
.\set-windows.ps1 -Uninstall
```

## 동작 방식

1. Chocolatey가 설치되어 있지 않으면 설치
2. 설치 시 `Server`, `Client`, `ServerAndClient` 중 역할 선택
3. 역할에 맞는 Chocolatey 패키지 설치: `sunshine`, `moonlight-qt.install`, `tailscale`
4. 서버 설정이면 로컬 Sunshine 웹 UI를 열고, 클라이언트 설정이면 `https://<서버주소>:47990/pin`을 열어 페어링 진행
5. Client 설정이 포함되면 Moonlight 실행
6. 제거 시 관리 대상 3개 패키지 전체 제거
