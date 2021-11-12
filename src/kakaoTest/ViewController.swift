//
//  ViewController.swift
//  kakaoTest
//
//  Created by seob_jj on 2021/11/12.
//

import UIKit
import RxSwift
import RxCocoa
import Alamofire

class ViewController: UIViewController {
    
    let disposBag = DisposeBag()
    
    let baseURL = "https://kox947ka1a.execute-api.ap-northeast-2.amazonaws.com/prod/users"
    let xAuthToken = "206abb85b59185e61dcd3d1c77372a77"
    var token: String?
    
    let trucks: PublishSubject<[Truck]> = PublishSubject()
    let locations: PublishSubject<[Location]> = PublishSubject()
    let simulations: PublishSubject<Simulate> = PublishSubject()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // trucks와 locations 둘다 새로운 데이터가 등록 되었을 시
        // simulate 돌리기
        Observable.zip(trucks, locations).subscribe(onNext: { _, _ in
            // MARK: TODO
            // simulate 하기 전에 뭔가 처리 Commnads 생성
            let commands = [Command(truck_id: 0, command: [1,2,3])]
            
            // 커맨드를 통해 시뮬레이션 돌리기
            // simulate() 반환된 Observable을 simulations에 등록
            self.simulate(commands).bind(to: self.simulations).disposed(by: self.disposBag)
        }).disposed(by: disposBag)
        
        // similations에 새로운 Observable이 등록 되었을 시
        simulations.subscribe(onNext: { simulate in
            // simulate.status가 ready인 경우 : 다음 loaction과 truck 받아서 trucks와 locations에 등록
            if simulate.status == "ready"{
                print(simulate)
                self.getTruck().bind(to: self.trucks).disposed(by: self.disposBag)
                self.getLocation().bind(to: self.locations).disposed(by: self.disposBag)
            // simulate.status가 finished인 경우 : 스코어 호출 및 출력
            } else {
                self.getScore().subscribe(onNext: { score in
                    print(score.score)
                }).disposed(by: self.disposBag)
            }
        }).disposed(by: disposBag)
        
    }
    
    @IBAction func startButtonTapped(_ sender: Any) {
        startTest().subscribe(onNext: { start in
            self.token = start.auth_key
            print("start: \(start)")
            
            self.getTruck().bind(to: self.trucks).disposed(by: self.disposBag)
            self.getLocation().bind(to: self.locations).disposed(by: self.disposBag)
        }).disposed(by: disposBag)
        

    }
    
    private func startTest() -> Observable<Start>{
        return Observable.create { observer in
            AF.request("\(self.baseURL)/start",
                       method: .post,
                       parameters: ["problem" : 1],
                       encoding: JSONEncoding.default,
                       headers: ["X-Auth-Token" : self.xAuthToken])
                .validate(statusCode: 200..<300)
                .responseJSON{ response in
                    guard let data = response.data else { return }
                    guard let start = try? JSONDecoder().decode(Start.self, from: data) else { return }
                    observer.onNext(start)
                }
            return Disposables.create()
        }
    }
    
    private func getTruck() -> Observable<[Truck]> {
        return Observable.create { observer in
            AF.request("\(self.baseURL)/trucks",
                       method: .get,
                       parameters: nil,
                       headers: ["Authorization" : self.token!])
                .validate(statusCode: 200..<300)
                .responseJSON{ response in
                    guard let data = response.data else { return }
                    guard let truckResponse = try? JSONDecoder().decode(TruckResponse.self, from: data) else { return }
                    observer.onNext(truckResponse.trucks)
                }
            return Disposables.create()
        }
    }
    
    
    private func getLocation() -> Observable<[Location]> {
        return Observable.create { observer in
            AF.request("\(self.baseURL)/locations",
                       method: .get,
                       parameters: nil,
                       headers: ["Authorization" : self.token!])
                .validate(statusCode: 200..<300)
                .responseJSON{ response in
                    guard let data = response.data else { return }
                    guard let locationResponse = try? JSONDecoder().decode(LocationResponse.self, from: data) else { return }
                    observer.onNext(locationResponse.locations)
                }
            return Disposables.create()
        }
    }
    
    private func simulate(_ commands: [Command]) -> Observable<Simulate> {
                
        var params = ["commands" : []]
        commands.forEach{
            let command: [String : Any] = ["truck_id" : $0.truck_id, "command" : $0.command]
            params["commands"]?.append(command)
        }
        
        return Observable.create { observer in
            AF.request("\(self.baseURL)/simulate",
                       method: .put,
                       parameters: params,
                       encoding: JSONEncoding.default,
                       headers: ["Authorization" : self.token!])
                .validate(statusCode: 200..<300)
                .responseJSON{ response in
                    guard let data = response.data else { return }
                    guard let simulate = try? JSONDecoder().decode(Simulate.self, from: data) else { return }
                    observer.onNext(simulate)
                }
            return Disposables.create()
        }
    }
    
    private func getScore() -> Observable<Score> {
        return Observable.create { observer in
            AF.request("\(self.baseURL)/score",
                       method: .get,
                       parameters: nil,
                       headers: ["Authorization" : self.token!])
                .validate(statusCode: 200..<300)
                .responseJSON{ response in
                    guard let data = response.data else {
                        return
                    }
                    guard let score = try? JSONDecoder().decode(Score.self, from: data) else {
                        print("parsing error")
                        return }
                    observer.onNext(score)
                }
            return Disposables.create()
        }
    }
}

