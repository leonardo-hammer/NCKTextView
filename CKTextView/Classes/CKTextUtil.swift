//
//  CKTextUtil.swift
//  Pods
//
//  Created by Chanricle King on 4/29/16.
//
//

import UIKit

enum ListKeywordType {
    case NumberedList
}

class CKTextUtil: NSObject {
    class func bezierPathWidthWithLineHeight(lineHeight: CGFloat) -> Int
    {
        return Int(lineHeight) + Int(lineHeight - 8)
    }
    
    class func isSpace(text: String) -> Bool
    {
        if text == " " {
            return true
        } else {
            return false
        }
    }
    
    class func isReturn(text: String) -> Bool
    {
        if text == "\n" {
            return true
        } else {
            return false
        }
    }
    
    class func isBackspace(text: String) -> Bool
    {
        if text == "" {
            return true
        } else {
            return false
        }
    }
    
    class func isEmptyLine(location:Int, textView: UITextView) -> Bool
    {
        let text = textView.text
        
        if text.endIndex == text.startIndex.advancedBy(location) {
            // last char of text.
            return true
        }
        
        let nextCharRange = Range(text.startIndex.advancedBy(location) ..< text.startIndex.advancedBy(location + 1))
        let keyChar = text.substringWithRange(nextCharRange)
        
        if keyChar == "\n" {
            return true
        }
        
        return false
    }
    
    class func isFirstLocationInLineWithLocation(location: Int, textView: UITextView) -> Bool
    {
        if location <= 0 {
            return true
        }
        
        let textString = textView.text
        
        let range: Range = Range(textString.startIndex.advancedBy(location - 1) ..< textString.startIndex.advancedBy(location))
        let keyChar = textView.text.substringWithRange(range)
        
        if keyChar == "\n" {
            return true
        } else {
            return false
        }
    }
    
    class func isSelectedTextMultiLine(textView: UITextView) -> Bool
    {
        if let selectedTextRange = textView.selectedTextRange {
            let startY = textView.caretRectForPosition(selectedTextRange.start).origin.y
            let endY = textView.caretRectForPosition(selectedTextRange.end).origin.y
            
            if startY != endY {
                return true
            }
        }
        
        return false
    }
    
    class func checkChangedTextInfoAndHandleMutilSelect(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> ([String], Bool, CGFloat)
    {
        let selectedRange = textView.selectedTextRange!
        
        let selectStartY = textView.caretRectForPosition(selectedRange.start).origin.y
        let selectEndY = textView.caretRectForPosition(selectedRange.end).origin.y
        
        var needsRemoveItemYArray = seletedPointYArrayWithTextView(textView, selectedRange: selectedRange, isContainFirstLine: false, sortByAsc: false)
        
        return (needsRemoveItemYArray, needsRemoveItemYArray.count > 0, selectStartY - selectEndY)
    }
    
    class func seletedPointYArrayWithTextView(textView: UITextView, selectedRange: UITextRange, isContainFirstLine containFirstLine: Bool, sortByAsc: Bool) -> [String]
    {
        let selectStartY = textView.caretRectForPosition(selectedRange.start).origin.y
        let selectEndY = textView.caretRectForPosition(selectedRange.end).origin.y
        
        var needsRemoveItemYArray: [String] = []
        
        var moveY = selectEndY
        
        let compareSelectStartY = selectStartY + 0.1
        
        if containFirstLine {
            needsRemoveItemYArray.append(String(Int(selectStartY)))
        }
        
        while moveY > compareSelectStartY {
            needsRemoveItemYArray.append(String(Int(moveY)))
            moveY -= textView.font!.lineHeight
        }
        
        if sortByAsc {
            needsRemoveItemYArray = needsRemoveItemYArray.sort({ ($0 as NSString).integerValue < ($1 as NSString).integerValue })
        }
        
        return needsRemoveItemYArray
    }
    
    class func itemTextHeightWithY(y: CGFloat, ckTextView: CKTextView) -> CGFloat {
        let lineHeight = ckTextView.font!.lineHeight
        
        let lineHeadPosition = ckTextView.closestPositionToPoint(CGPoint(x: CGFloat(CKTextUtil.bezierPathWidthWithLineHeight(lineHeight)) + ckTextView.font!.pointSize / 2, y: y + (lineHeight / 2)))
        
        let textStartIndex = ckTextView.offsetFromPosition(ckTextView.beginningOfDocument, toPosition: lineHeadPosition!)
        var textEndIndex: Int
        
        let checkedText = ckTextView.text.substringFromIndex(ckTextView.text.startIndex.advancedBy(textStartIndex))
        
        print("checkedText: \(checkedText)")
        
        let range = (checkedText as NSString).rangeOfString("\n")
        if range.location != NSNotFound {
            textEndIndex = range.location
            textEndIndex += textStartIndex
        } else {
            textEndIndex = ckTextView.offsetFromPosition(ckTextView.beginningOfDocument, toPosition: ckTextView.endOfDocument)
        }
        
        let startPosition = ckTextView.positionFromPosition(ckTextView.beginningOfDocument, offset: textStartIndex)
        let endPosition = ckTextView.positionFromPosition(ckTextView.beginningOfDocument, offset: textEndIndex)
        
        let itemTextRange = ckTextView.textRangeFromPosition(startPosition!, toPosition: endPosition!)
        let selectionRects = ckTextView.selectionRectsForRange(itemTextRange!)
        
        var heights: CGFloat = 0.0
        
        selectionRects.filter({ $0.rect.width > 0 }).map({ heights += $0.rect.height })
        
        heights -= 1.5
        
        if heights < lineHeight {
            heights = lineHeight
        }
        
        print("itemTextRange: \(itemTextRange)")
        print("heights: \(heights)")
        
        return heights
    }
    
    // FIXME: Bad performance
    class func heightWithText(text: String, textView: UITextView, listType: ListType, numberIndex: Int) -> (CGFloat, String)
    {
        let calcTextView = UITextView(frame: CGRect(x: 0, y: 0, width: textView.bounds.width, height: CGFloat.max))
        calcTextView.font = textView.font
    
        if listType != ListType.Text {
            let numberKeyword = "\(numberIndex). "
            
            let listTypeLengthDict = [ListType.Numbered: numberKeyword.characters.count, ListType.Bulleted: 2, ListType.Checkbox: 6]
            
            let lineHeight = calcTextView.font!.lineHeight
            let width = CKTextUtil.bezierPathWidthWithLineHeight(lineHeight)
            
            calcTextView.textContainer.exclusionPaths.append(UIBezierPath(rect: CGRect(x: 0, y: 0, width: width, height: Int.max)))
            
            let prefixLength = listTypeLengthDict[listType]!
            
            calcTextView.text = text.substringFromIndex(text.startIndex.advancedBy(listTypeLengthDict[listType]!))
            
        } else {
            calcTextView.text = text
        }
        
        return (textHeightForTextView(calcTextView), calcTextView.text)
    }
    
    // FIXME: Bad performance
    class func heightWithKeyText(text: String, textView: UITextView, listType: ListType, numberIndex: Int) -> (CGFloat, String)
    {
        let calcTextView = UITextView(frame: CGRect(x: 0, y: 0, width: textView.bounds.width, height: CGFloat.max))
        calcTextView.font = textView.font
        
        if listType != ListType.Text {
            let numberKeyword = "\(numberIndex). "
            
            let listTypeLengthDict = [ListType.Numbered: 3, ListType.Bulleted: 3, ListType.Checkbox: 3]
            
            let lineHeight = calcTextView.font!.lineHeight
            let width = CKTextUtil.bezierPathWidthWithLineHeight(lineHeight)
            
            calcTextView.textContainer.exclusionPaths.append(UIBezierPath(rect: CGRect(x: 0, y: 0, width: width, height: Int.max)))
            
            let prefixLength = listTypeLengthDict[listType]!
            
            calcTextView.text = text.substringFromIndex(text.startIndex.advancedBy(listTypeLengthDict[listType]!))
            
        } else {
            calcTextView.text = text
        }
        
        return (textHeightForTextView(calcTextView), calcTextView.text)
    }
    
    class func clearTextByRange(range: NSRange, textView: UITextView)
    {
        let clearRange = Range(textView.text.startIndex.advancedBy(range.location) ..< textView.text.startIndex.advancedBy(range.location + range.length))
        textView.text.replaceRange(clearRange, with: "")
    }
    
    class func textByRange(range: NSRange, text: String) -> String
    {
        let targetRange = Range(text.startIndex.advancedBy(range.location) ..< text.startIndex.advancedBy(range.location + range.length))
        return text.substringWithRange(targetRange)
    }
    
    class func typeForListKeywordWithLocation(location: Int, textView: UITextView) -> ListType
    {
        let checkArray = [("1.", 2, ListType.Numbered), ("*", 1, ListType.Bulleted), ("[]", 2, ListType.Checkbox)]
        
        for (_, value) in checkArray.enumerate() {
            let keyword = value.0
            let length = value.1
            let listType = value.2
            
            let keyChars = self.keyCharsWithLocation(location, textView: textView, length: length)
            
            if keyChars == keyword {
                return listType
            }
        }
        
        return ListType.Text
    }
    
    class func lineHeadIndexWithPosition(position: UITextPosition, ckTextView:CKTextView) -> Int
    {
        // Get target y
        let cursorIndex = ckTextView.offsetFromPosition(ckTextView.beginningOfDocument, toPosition: position)
        let checkText = ckTextView.text.substringToIndex(ckTextView.text.startIndex.advancedBy(cursorIndex))
        
        let lineHeadIndex: Int
        
        let searchRange = (checkText as NSString).rangeOfString("\n", options: .BackwardsSearch)
        if searchRange.location != NSNotFound {
            lineHeadIndex = searchRange.location + 1
        } else {
            lineHeadIndex = 0
        }
        
        return lineHeadIndex
    }
    
    class func lineHeadPositionWithPosition(position: UITextPosition, ckTextView:CKTextView) -> UITextPosition
    {
        let lineHeadIndex = lineHeadIndexWithPosition(position, ckTextView: ckTextView)
        let lineHeadPosition = ckTextView.positionFromPosition(ckTextView.beginningOfDocument, offset: lineHeadIndex)
        
        return lineHeadPosition!
    }
    
    class func lineHeadPointYWithPosition(position: UITextPosition, ckTextView:CKTextView) -> CGFloat
    {
        // Get target y
        let lineHeadPosition = self.lineHeadPositionWithPosition(position, ckTextView: ckTextView)
        let targetY = ckTextView.caretRectForPosition(lineHeadPosition).origin.y
        
        return targetY
    }
    
    class func lineHeadPointYWithLineHeadPosition(lineHeadPosition: UITextPosition, ckTextView: CKTextView) -> CGFloat
    {
        let targetY = ckTextView.caretRectForPosition(lineHeadPosition).origin.y
        
        return targetY
    }
    
    class func lineHeadPointYWithLineHeadIndex(index: Int, ckTextView: CKTextView) -> CGFloat
    {
        let lineHeadPosition = ckTextView.positionFromPosition(ckTextView.beginningOfDocument, offset: index)
        let targetY = ckTextView.caretRectForPosition(lineHeadPosition!).origin.y
        
        return targetY
    }
    
    private class func keyCharsWithLocation(location: Int, textView: UITextView, length: Int) -> String
    {
        guard location >= length && CKTextUtil.isFirstLocationInLineWithLocation(location - length, textView: textView) else { return "" }
        
        let textString = textView.text
        let range: Range = Range(textString.startIndex.advancedBy(location - length) ..< textString.startIndex.advancedBy(location))
        let keyChars = textView.text.substringWithRange(range)
        
        return keyChars
    }
    
    class func textHeightForTextView(textView: UITextView) -> CGFloat
    {
        let textHeight = textView.layoutManager.usedRectForTextContainer(textView.textContainer).height
        return textHeight
    }
    
    class func cursorPointInTextView(textView: UITextView) -> CGPoint
    {
        return textView.caretRectForPosition(textView.selectedTextRange!.start).origin
        
    }
    
    class func typeOfCharacter(character: String, numberIndex: Int) -> ListType
    {
        let numberKeyword = "\(numberIndex). "
        
        let checkArray = [(numberKeyword, numberKeyword.characters.count, ListType.Numbered), ("* ", 2, ListType.Bulleted), ("- [ ] ", 6, ListType.Checkbox), ("- [x] ", 6, ListType.Checkbox)]
        
        for (_, value) in checkArray.enumerate() {
            let keyword = value.0
            let length = value.1
            let listType = value.2
            
            if character.characters.count < length {
                continue
            }
            
            let range: Range = Range(character.startIndex ..< character.startIndex.advancedBy(length))
            let keyChars = character.substringWithRange(range)
            
            if keyChars == keyword {
                return listType
            }
        }
        
        return ListType.Text
    }
    
    class func typeOfKeyCharacter(keyCharacter: String) -> ListType
    {
        let checkArray = [("@ :", 3, ListType.Numbered), ("* :", 3, ListType.Bulleted), ("c :", 3, ListType.Checkbox), ("cc:", 3, ListType.Checkbox)]
        
        for (_, value) in checkArray.enumerate() {
            let keyword = value.0
            let length = value.1
            let listType = value.2
            
            if keyCharacter.characters.count < length {
                continue
            }
            
            let range: Range = Range(keyCharacter.startIndex ..< keyCharacter.startIndex.advancedBy(length))
            let keyChars = keyCharacter.substringWithRange(range)
            
            if keyChars == keyword {
                return listType
            }
        }
        
        return ListType.Text
    }
    
    class func resetKeyYSetItem(item: BaseListItem, startY: CGFloat, textHeight: CGFloat, lineHeight: CGFloat)
    {
        var keyYSet: Set<CGFloat> = Set()
        
        var y = startY
        var moveY = textHeight
        
        while Int(moveY) >= Int(lineHeight) {
            keyYSet.insert(y)
            y += lineHeight
            
            moveY -= lineHeight
        }
        
        item.keyYSet = keyYSet
    }
    
    // MARK: - KeyText and NormalText Convertion
    
    public class func changeToKeyTextWithNormalText(normalText: String, textView: UITextView) -> String
    {
        var allLineCharacters = (normalText as NSString).componentsSeparatedByString("\n")
        
        var numberIndex = 1
        
        for (index, character) in allLineCharacters.enumerate() {
            let listType = CKTextUtil.typeOfCharacter(character, numberIndex: numberIndex)
            
            let textHeightAndNewText = CKTextUtil.heightWithText(character, textView: textView, listType: listType, numberIndex: numberIndex)
            let newCharacter = textHeightAndNewText.1
            
            if listType == ListType.Numbered {
                numberIndex += 1
            } else {
                numberIndex = 1
            }
            
            var listPrefix = ""
            
            switch listType {
            case .Numbered:
                listPrefix = "@ :"
                break
            case .Bulleted:
                listPrefix = "* :"
                break
            case .Checkbox:
                if character.rangeOfString("- [x] ") != nil {
                    listPrefix = "cc:"
                } else {
                    listPrefix = "c :"
                }
                break
            case .Text:
                break
            }
            
            // Change characters, remove prefix keyword.
            allLineCharacters[index] = listPrefix + newCharacter
        }
        
        return allLineCharacters.joinWithSeparator("\n")
    }
    
    public class func changeToNormalTextWithKeyText(keyText: String, textView: UITextView) -> String
    {
        var allLineCharacters = (keyText as NSString).componentsSeparatedByString("\n")
        
        var numberIndex = 1
        
        for (index, character) in allLineCharacters.enumerate() {
            let listType = CKTextUtil.typeOfKeyCharacter(character)
            
            let textHeightAndNewText = CKTextUtil.heightWithKeyText(character, textView: textView, listType: listType, numberIndex: numberIndex)
            let newCharacter = textHeightAndNewText.1
            
            var listPrefix = ""
            
            switch listType {
            case .Numbered:
                listPrefix = "\(numberIndex). "
                break
            case .Bulleted:
                listPrefix = "* "
                break
            case .Checkbox:
                if character.rangeOfString("cc:") != nil {
                    listPrefix = "- [x] "
                } else {
                    listPrefix = "- [ ] "
                }
                break
            case .Text:
                break
            }
            
            // Change characters, remove prefix keyword.
            allLineCharacters[index] = listPrefix + newCharacter
            
            if listType == ListType.Numbered {
                numberIndex += 1
            } else {
                numberIndex = 1
            }
        }
        
        return allLineCharacters.joinWithSeparator("\n")
    }
    
    public class func changeToTextWithKeyText(keyText: String) -> String
    {
        var allLineCharacters = (keyText as NSString).componentsSeparatedByString("\n")
        
        var numberIndex = 1
        
        for (index, character) in allLineCharacters.enumerate() {
            let listType = CKTextUtil.typeOfKeyCharacter(character)
            
            if listType != .Text {
                allLineCharacters[index] = character.substringFromIndex(character.startIndex.advancedBy(3))
            }
        }
        
        return allLineCharacters.joinWithSeparator("\n")
    }
    
    class func keyTypePrefixWithListType(listType: ListType) -> String
    {
        switch listType {
        case .Numbered:
            return "@ :"
        case .Bulleted:
            return "* :"
        case .Checkbox:
            return "c :"
        case .Text:
            return ""
        }
    }
}
