# Programmers : 2021 Kakao 2차 코딩테스트

**Swift** 언어를 이용한 API 통신 및 문제풀이

[programmers :  2021 Kakao 2차 코딩테스트 문제 링크](https://programmers.co.kr/skill_check_assignments/67)

## API 통신

해당 문제에서는 Start API를 통해 token 데이터 습득하면서 문제를 시작한다. 그 후 Location API 와 Truck API 를 통해서 데이터를 얻고 해당 데이터를 통해 트럭들을 어떻게 동작시킬지에 대한 `commands`를 결정한 후 (문제 풀이) 해당 `commands`를 Simulate API 를 통해 실행한다. 위의 과정을 반복하며 시간을 늘려나간 후 마지막 Simulate API 의 응답결과의 `status`가 finished가 되면 Score API 를 통해 점수를 확인할 수 있다.

### Only URLSession

처음 풀이는 오직 `URLSession` 통신만 사용해서 API에 접근하려는 시도를 하였다. `URLSession` 의 `dataTask` 같은 경우 `completeHandler` 에 대한 클로져가 `escaping` 속성을 갖기 때문에 함수의 종료와 관계없이 비동기적으로 완료 작업을 처리한다. 하지만 해당 문제에서는 Start - (( Location & Truck ) - Simulate) 반복 - Score 와 같이 작업들이 순서를 가지고 실행해야 한다. 처음에는 얄팍한 시도로 Start API completion handler 에 Location API 그리고 Location API completion Handler 안에 Truck API ... 이런식으로 코드를 구성했지만 당연히 짧은 시간안에 (최소 720번 이상의) 콜백 지옥을 경험하게 될것을 감지 하고 포기 하였다. 

### URLSession & Semaphore

`URLSession` 을 통한 API 호출 함수 각각을 동기적으로 실행할 수 있는 방법이 없을까에 대해 고민하다가, `Semaphore`를 사용하여 `escaping closure`인 `completionHandler`를 일반 `closure`와 같이 동작하도록 만드는 방법을 채택하였다. 함수 리턴 직전에 `semaphore`를 `wait()` 시킨 후 `completionHandler` 내에서 모든 작업이 끝나면 `semaphore`에 `signal()`을 해주고 원하는 값을 리턴할 수 있도록 하였다. 이와 같은 방법으로 원하는 방식으로 API 통신의 순서를 지키는 것이 가능하였다.

### :star:RxSwift

`Semaphore`를 사용하지 않고 하는 방법은 없을까? 에 대해서 고민하다가 비동기적인 작업을 획기적으로 관리할 수 있다고 소문난 RxSwift까지 사용해보기로 결심하였다.

결론은 성공적으로 RxSwift를 사용하여 (개인적으로) 원했던 모습의 코드를 만들 수 있었다.

#### API 통신을 위한 함수들

각 API 호출하는 역할을 맡는 함수들은 아래와 같이 `Observable` 을 리턴하고 각 `Observable` 은 `onNext` 로 API 통신 결과를 받을 수 있다. 

`func getSomething() -> Observable<something>` 

#### setup RxSwift

1.  truck, location, simulate 에 대한 `PublishSubject` 를 생성해 놓았다. 
2. `Observable.zip()` 를 사용하여 truck과 location에 대한 `Subject`에 `Observable`이 둘다 업데이트 된 경우에 해당 정보들을 토대로 다음 simulate에 넣을 `commands`를 구하게 한다. 
3. 그 후 생성된 commands를 이용하여 simulate를 실행하는 API 통신 함수를 실행하고 반환되는 `Observable`을 해당하는 `Subject`에 `bind` 해준다. 
4. Simulate 에 대한 `Subject`에 새로운 `Observable`이 업데이트 되면  결과의 status를 체크후 `ready`인 경우에는 Truck과 Location에 대한 정보를 불러오는 API 함수를 실행하고 반환되는 `Observable`을 각 `subject`에 바인딩해준다. 
5. 위의 동작이 반복되면서 status가 finished가 될 때 까지 작업 순서를 맞춰가면서 실행 시킬 수 있다. 
6. 마지막으로 `status`가 `finished`가 되면 Score를 불러와 출력한다.



## 문제풀이 (Commands 구하기)

TODO
