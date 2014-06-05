//
//  GameScene.swift
//  FlappyBird
//
//  Created by Nate Murray on 6/2/14.
//  Copyright (c) 2014 Fullstack.io. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    let verticalPipeGap = 150.0
    let birdCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let skyColor: SKColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
    
    var bird = SKSpriteNode()
    var pipeTextureUp = SKTexture()
    var pipeTextureDown = SKTexture()
    var movePipesAndRemove = SKAction()
    var moving = SKNode()
    var pipes = SKNode()
    var canRestart: Bool = false
    
    override func didMoveToView(view: SKView) {
        // setup physics
        self.physicsWorld.gravity = CGVectorMake( 0.0, -5.0 )
        self.physicsWorld.contactDelegate = self
        
        // setup background color
        self.backgroundColor = skyColor
        
        self.addChild(moving)
        self.addChild(pipes)
        
        // ground
        var groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        var moveGroundSprite = SKAction.moveByX(-groundTexture.size().width * 2.0, y: 0, duration: NSTimeInterval(0.02 * groundTexture.size().width * 2.0))
        var resetGroundSprite = SKAction.moveByX(groundTexture.size().width * 2.0, y: 0, duration: 0.0)
        var moveGroundSpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]))
        
        for var i:CGFloat = 0; i < 2.0 + self.frame.size.width / ( groundTexture.size().width * 2.0 ); ++i {
            var sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2.0)
            sprite.runAction(moveGroundSpritesForever)
            moving.addChild(sprite)
        }
        
        // skyline
        var skyTexture = SKTexture(imageNamed: "sky")
        skyTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        var moveSkySprite = SKAction.moveByX(-skyTexture.size().width * 2.0, y: 0, duration: NSTimeInterval(0.1 * skyTexture.size().width * 2.0))
        var resetSkySprite = SKAction.moveByX(skyTexture.size().width * 2.0, y: 0, duration: 0.0)
        var moveSkySpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveSkySprite,resetSkySprite]))
        
        for var i:CGFloat = 0; i < 2.0 + self.frame.size.width / ( skyTexture.size().width * 2.0 ); ++i {
            var sprite = SKSpriteNode(texture: skyTexture)
            sprite.setScale(2.0)
            sprite.zPosition = -20
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2.0 + groundTexture.size().height * 2.0)
            sprite.runAction(moveSkySpritesForever)
            moving.addChild(sprite)
        }
        
        // create the pipes textures
        pipeTextureUp = SKTexture(imageNamed: "PipeUp")
        pipeTextureUp.filteringMode = SKTextureFilteringMode.Nearest
        pipeTextureDown = SKTexture(imageNamed: "PipeDown")
        pipeTextureDown.filteringMode = SKTextureFilteringMode.Nearest
        
        // create the pipes movement actions
        var distanceToMove = CGFloat(self.frame.size.width + 2.0 * pipeTextureUp.size().width)
        var movePipes = SKAction.moveByX(-distanceToMove, y:0.0, duration:NSTimeInterval(0.01 * distanceToMove))
        var removePipes = SKAction.removeFromParent()
        movePipesAndRemove = SKAction.sequence([movePipes, removePipes])
        
        // spawn the pipes
        var spawn = SKAction.runBlock({self.spawnPipes()})
        var delay = SKAction.waitForDuration(NSTimeInterval(2.0))
        var spawnThenDelay = SKAction.sequence([spawn, delay])
        var spawnThenDelayForever = SKAction.repeatActionForever(spawnThenDelay)
        self.runAction(spawnThenDelayForever)
        
        // setup our bird
        var birdTexture1 = SKTexture(imageNamed: "bird-01")
        birdTexture1.filteringMode = SKTextureFilteringMode.Nearest
        var birdTexture2 = SKTexture(imageNamed: "bird-02")
        birdTexture2.filteringMode = SKTextureFilteringMode.Nearest
        
        var anim = SKAction.animateWithTextures([birdTexture1, birdTexture2], timePerFrame: 0.2)
        var flap = SKAction.repeatActionForever(anim)
        
        bird = SKSpriteNode(texture: birdTexture1)
        bird.setScale(2.0)
        bird.position = CGPoint(x: self.frame.size.width * 0.35, y:self.frame.size.height * 0.6)
        bird.runAction(flap)
        
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody.categoryBitMask = birdCategory
        bird.physicsBody.collisionBitMask = worldCategory | pipeCategory
        bird.physicsBody.contactTestBitMask = worldCategory | pipeCategory
        bird.physicsBody.dynamic = true
        bird.physicsBody.allowsRotation = false
        
        self.addChild(bird)
        
        // create the ground
        var ground = SKNode()
        ground.position = CGPointMake(0, groundTexture.size().height)
        ground.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, groundTexture.size().height * 2.0))
        ground.physicsBody.categoryBitMask = worldCategory
        ground.physicsBody.dynamic = false
        self.addChild(ground)
        
        
    }
    
    func spawnPipes() {
        var pipePair = SKNode()
        pipePair.position = CGPointMake( self.frame.size.width + pipeTextureUp.size().width * 2, 0 )
        pipePair.zPosition = -10
        
        var height = UInt32( self.frame.size.height / 4 )
        var y = arc4random() % height + height
        
        var pipeDown = SKSpriteNode(texture: pipeTextureDown)
        pipeDown.setScale(2.0)
        pipeDown.position = CGPointMake(0.0, CGFloat(y) + pipeDown.size.height + CGFloat(verticalPipeGap))
        
        pipeDown.physicsBody = SKPhysicsBody(rectangleOfSize: pipeDown.size)
        pipeDown.physicsBody.categoryBitMask = pipeCategory
        pipeDown.physicsBody.contactTestBitMask = birdCategory
        pipeDown.physicsBody.dynamic = false
        pipePair.addChild(pipeDown)
        
        var pipeUp = SKSpriteNode(texture: pipeTextureUp)
        pipeUp.setScale(2.0)
        pipeUp.position = CGPointMake(0.0, CGFloat(y))
        
        pipeUp.physicsBody = SKPhysicsBody(rectangleOfSize: pipeUp.size)
        pipeUp.physicsBody.categoryBitMask = pipeCategory
        pipeUp.physicsBody.contactTestBitMask = birdCategory
        pipeUp.physicsBody.dynamic = false
        pipePair.addChild(pipeUp)
        
        pipePair.runAction(movePipesAndRemove)
        pipes.addChild(pipePair)
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        if (moving.speed > 0 ) {
            moving.speed = 0
            pipes.speed = 0
            canRestart = true
            var rotate = SKAction.rotateToAngle(CGFloat(bird.position.y * 3.14159 * 0.01), duration: NSTimeInterval(bird.position.y * 0.003))
            bird.runAction(rotate)
            self.backgroundColor = SKColor.redColor()

            var wait = SKAction.waitForDuration(NSTimeInterval(0.01))

            var makeRed = SKAction.runBlock({
                self.backgroundColor = SKColor.redColor()
                })
            
            var makeSky = SKAction.runBlock({
                self.backgroundColor = self.skyColor
                })
            
            self.runAction(SKAction.repeatAction(SKAction.sequence([wait, makeRed, wait, makeSky]), count: 4))
        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        if (moving.speed > 0) {
            for touch: AnyObject in touches {
                let location = touch.locationInNode(self)
                
                bird.physicsBody.velocity = CGVectorMake(0, 0)
                bird.physicsBody.applyImpulse(CGVectorMake(0, 30))
            }
        } else if (canRestart) {
            self.resetScene()
        }
        
    }
    
    func resetScene() {
        bird.position = CGPoint(x: self.frame.size.width * 0.35, y:self.frame.size.height * 0.6)
        bird.physicsBody.velocity = CGVectorMake(0, 0)
        
        pipes.removeAllChildren()
        
        canRestart = false
        
        moving.speed = 1
        pipes.speed = 2
        
        self.backgroundColor = skyColor
    }
    
    func clamp(min: CGFloat, max: CGFloat, value: CGFloat) -> CGFloat {
        if( value > max ) {
            return max
        } else if( value < min ) {
            return min
        } else {
            return value
        }
    }
    
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        bird.zRotation = self.clamp( -1, max: 0.5, value: bird.physicsBody.velocity.dy * ( bird.physicsBody.velocity.dy < 0 ? 0.003 : 0.001 ) )
    }
}
